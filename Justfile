setup:
  #!/bin/bash
  # TODO: idempotency

  # TODO: check for macos
  mkdir -p ./bin/helm-docs-1.5.0/
  curl -L https://github.com/norwoodj/helm-docs/releases/download/v1.5.0/helm-docs_1.5.0_Darwin_x86_64.tar.gz | tar -xzvf - -C ./bin/helm-docs-1.5.0/
  ln -s $PWD/bin/helm-docs-1.5.0/helm-docs $PWD/bin/helm-docs

update-lock:
  #!/bin/bash
  set -xe
  orig_dir=$(pwd)
  for dir in `ls charts`; do
    echo " --> Updating Chart.lock for $dir"
    cd "charts/$dir" && helm dependency update
    cd $orig_dir
  done
  echo " --> Done!"

all-docs:
  just docs rbac

docs:
  #!/bin/bash
  ./bin/helm-docs --chart-search-root=charts --template-files=README.md.gotmpl --template-files=./_templates.gotmpl
  ./bin/helm-docs --chart-search-root=other-charts --template-files=README.md.gotmpl --template-files=./_templates.gotmpl

rbac:
  #!/bin/bash
  set -xe
  cd ./charts/rstudio-launcher-rbac && helm dependency update && helm dependency build && cd -
  helm template -n rstudio rstudio-launcher-rbac ./charts/rstudio-launcher-rbac --set removeNamespaceReferences=true > examples/rbac/rstudio-launcher-rbac.yaml
  CHART_VERSION=$(helm show chart ./charts/rstudio-launcher-rbac | grep '^version' | cut -d ' ' -f 2)
  cp examples/rbac/rstudio-launcher-rbac.yaml examples/rbac/rstudio-launcher-rbac-${CHART_VERSION}.yaml

lint:
  #!/bin/bash
  ct lint ./charts --target-branch main

snapshot-rsw:
  #!/bin/bash
  set -xe

  helm template ./charts/rstudio-workbench --set global.secureCookieKey="abc" --set launcherPem="abc" > charts/rstudio-workbench/snapshot/default.yaml
  
  for file in `ls ./charts/rstudio-workbench/ci/*.yaml`; do
    filename=$(basename $file)
    helm template ./charts/rstudio-workbench --set global.secureCookieKey="abc" --set launcherPem="abc" -f $file > charts/rstudio-workbench/snapshot/$filename
  done

snapshot-rsw-lock:
  #!/bin/bash
  set -xe
  for file in `ls ./charts/rstudio-workbench/snapshot/*.yaml`; do
    cp $file $file.lock
  done

snapshot-rsw-diff:
  #!/bin/bash
  for file in `ls ./charts/rstudio-workbench/snapshot/*.yaml`; do
    echo Diffing $file
    diff $file $file.lock
  done
