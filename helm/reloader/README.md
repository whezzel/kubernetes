# Deploy reloader

A Kubernetes controller to watch changes in ConfigMap and Secrets and do rolling upgrades on Pods with their associated Deployment, StatefulSet, DaemonSet and DeploymentConfig

- <https://github.com/stakater/Reloader>
- <https://docs.stakater.com/reloader>

## Deploy reloader using helm

```bash
helm upgrade --install reloader reloader \
    --repo https://stakater.github.io/stakater-charts \
    --namespace reloader \
    --create-namespace
```

## Dump chart values

```bash
helm show values reloader --repo https://stakater.github.io/stakater-charts > ./helm/reloader/default-values.yaml
```
