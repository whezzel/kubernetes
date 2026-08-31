# Deploy Cilium

```bash
helm upgrade --install cilium cilium \
    --repo https://helm.cilium.io \
    --namespace cilium \
    --create-namespace \
    --values ./helm/cilium/values.yaml \
    --post-renderer dualstack
```

## Dump chart values

```bash
helm show values cilium --repo https://helm.cilium.io > ./helm/cilium/default-values.yaml
```

helm upgrade --install cilium-preflight cilium \
    --repo https://helm.cilium.io \
    --version 1.17.5 \
    --namespace=cilium \
    --set preflight.enabled=true \
    --set agent=false \
    --set operator.enabled=false
