# Deploy Longhorn

Longhorn is a distributed storage solution. It allows us to create storage volumes with replicas for resiliency. It allows storage to stay available even if one of your nodes goes down.

- <https://longhorn.io/docs/latest/deploy/install/install-with-helm>

## Deploy longhorn using helm

```bash
helm upgrade --install longhorn longhorn \
    --repo https://charts.longhorn.io \
    --namespace longhorn \
    --create-namespace \
    --values ./helm/longhorn/values.yaml
```

## Deploy supporting manifests

```bash
k apply -Rf ./helm/longhorn/
```

## Dump chart values

```bash
helm show values longhorn --repo https://charts.longhorn.io > ./helm/longhorn/temp-values.yaml
```
