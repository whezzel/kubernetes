# Deploy keel.sh

Manually updating workloads is annoying, but keel.sh allows us to automate that.

- <https://keel.sh/docs/#deploying-with-helm>

## Deploy keel.sh using helm

```bash
helm upgrade --install keel keel \
    --repo https://charts.keel.sh \
    --namespace=keel \
    --create-namespace \
    --values ./helm/keel/values.yaml
```

## Dump chart values

```bash
helm show values keel --repo https://charts.keel.sh > ./helm/keel/temp-values.yaml
```
