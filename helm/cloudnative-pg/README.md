# Cloudnative-pg

## Upgrades

Please carefully read the release notes before performing an upgrade as some versions might require extra steps.

- <https://cloudnative-pg.io/documentation/current/release_notes>

## Deploy cloudnative-pg with helm

```bash
helm upgrade --install cloudnative-pg cloudnative-pg \
    --repo https://cloudnative-pg.github.io/charts \
    --namespace database \
    --create-namespace \
    --values ./helm/cloudnative-pg/values.yaml
```

## Deploy Barman Cloud Plugin

```bash
wget -q -O - https://github.com/cloudnative-pg/plugin-barman-cloud/releases/latest/download/manifest.yaml | sed -E 's/namespace:[[:space:]]*[^[:space:]]+/namespace: database/g' | ka -f -
```

## Dump chart values

```bash
helm show values cloudnative-pg --repo https://cloudnative-pg.github.io/charts > ~/repos/k8s/helm/cloudnative-pg/temp-values.yaml
```
