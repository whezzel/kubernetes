# Cloudnative-pg

## Upgrades

Please carefully read the release notes before performing an upgrade as some versions might require extra steps.

- <https://cloudnative-pg.io/documentation/current/release_notes>

## Deploy cloudnative-pg with helm

```bash
helm upgrade --install cloudnative-pg cloudnative-pg \
    --repo https://cloudnative-pg.github.io/charts \
    --namespace cnpg \
    --create-namespace \
    --values ./helm/cloudnative-pg/values.yaml
```

## Dump chart values

```bash
helm show values cloudnative-pg --repo https://cloudnative-pg.github.io/charts > ~/repos/k8s/helm/cloudnative-pg/temp-values.yaml
```
