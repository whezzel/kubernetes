# Deploy kubed
Cert Manager stores the certficates as secrets, and screts are only accessible in the namespace they belong to. Kubed allows us to copy secrets to other namespaces automatically.

- https://appscode.com/products/kubed/v0.12.0/setup/install/

**Deploy kubed using helm:**
```bash
helm upgrade --install kubed kubed \
    --repo https://charts.appscode.com/stable/ \
    --namespace kubed \
    --create-namespace \
    --set apiserver.enabled=false \
    --set config.clusterName=prod
```
### **Setup your secrets and namespaces for syncing:**
- https://appscode.com/products/kubed/latest/guides/config-syncer/intra-cluster/

Annotate the secret you want to sync:
```bash
kubectl annotate secrets -n cert-manager <SECRET_NAME> kubed.appscode.com/sync="app=kubed"
```
and the namespaces we want to sync it to:
```bash
kubectl label namespace <NAMESPACE> app=kubed
```
