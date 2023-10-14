## **Deploy keel.sh**
Manually updating workloads is annoying, but keel.sh allows us to automate that.

- https://keel.sh/docs/#deploying-with-helm

**Deploy keel.sh using helm:**
```bash
helm upgrade --install keel keel \
    --repo https://charts.keel.sh \
    --namespace=keel \
    --create-namespace \
    --set "nodeSelector\.kubernetes\.io\/arch"=amd64 \
    --values ~/repos/k3s/helm/keel/values.yaml
```
