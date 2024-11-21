```bash
helm upgrade --install authentik-remote-cluster authentik-remote-cluster \
    --repo https://charts.goauthentik.io/ \
    --namespace auth \
    --values ~/repos/k3s/helm/authentik-remote-cluster/values.yaml
```
