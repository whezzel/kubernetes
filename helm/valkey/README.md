# Groundhog2k Valkey

Groundhog2k Valkey is a Helm chart for deploying Valkey, a high-performance key/value datastore. It supports Sentinel mode for high availability with a single primary-replica setup, ideal for non-sharded workloads requiring automatic failover.

## Deploy Groundhog2k valkey chart
```bash
helm upgrade --install valkey valkey \
    --repo https://groundhog2k.github.io/helm-charts \
    --namespace valkey \
    --create-namespace \
    --values ./helm/valkey/values.yaml
```

## Dump chart values
```bash
helm show values valkey --repo https://groundhog2k.github.io/helm-charts > ./helm/valkey/temp-values.yaml
```
