# Groundhog2k Valkey

Groundhog2k Valkey is a Helm chart for deploying Valkey, a high-performance key/value datastore. It supports Sentinel mode for high availability with a single primary-replica setup, ideal for non-sharded workloads requiring automatic failover.

## Deploy Groundhog2k valkey chart
```bash
helm upgrade --install <APPNAME>-valkey valkey \
    --repo https://groundhog2k.github.io/helm-charts \
    --namespace valkey \
    --create-namespace \
    --values ./helm/valkey/<APPNAME>/values.yaml \
    --post-renderer dualstack
```

## Dump chart values
```bash
helm show values valkey --repo https://groundhog2k.github.io/helm-charts > ./helm/valkey/default-values.yaml
```

## Patch service for dualstack
```bash
kubectl get svc -n valkey -o name | while read svc; do
  kubectl patch "$svc" -n valkey --type merge -p '{
    "spec": {
      "ipFamilyPolicy": "PreferDualStack",
      "ipFamilies": ["IPv4", "IPv6"]
    }
  }'
done
```
