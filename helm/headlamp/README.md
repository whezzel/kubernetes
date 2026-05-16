# Deploy Headlamp

Headlamp.

- <https://headlamp.dev/>
- <https://headlamp.dev/docs/latest/installation/in-cluster/>

## Deploy headlamp using helm

```bash
helm upgrade --install headlamp headlamp \
    --repo https://kubernetes-sigs.github.io/headlamp \
    --namespace kube-system \
    --create-namespace \
    --values ./helm/headlamp/values.yaml \
    --values ./helm/headlamp/secret-values.yaml
```

## Generate token for service account

```bash
kubectl create token headlamp --namespace kube-system
```

## Dump chart values

```bash
helm show values headlamp --repo https://kubernetes-sigs.github.io/headlamp > ./helm/headlamp/default-values.yaml
```
