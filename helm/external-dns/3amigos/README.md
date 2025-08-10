# Deploy External-DNS

External-DNS tracks svc/ing and creates dns records

- <https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/README.md>

## Apply supporting manifests

```bash
kubectl apply -f ./helm/external-dns/3amigos/00_secrets.yaml
```

## Deploy External-DNS using helm

```bash
helm upgrade --install external-dns-3amigos external-dns \
    --repo https://kubernetes-sigs.github.io/external-dns \
    --namespace dns \
    --create-namespace \
    --values ./helm/external-dns/3amigos/values.yaml
```
