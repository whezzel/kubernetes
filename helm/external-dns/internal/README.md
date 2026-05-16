# Deploy External-DNS

External-DNS tracks svc/ing and creates dns records

- <https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/README.md>

## Apply secrets

```bash
kubectl apply -f ./helm/external-dns/internal/00_secrets.yaml
```

## Deploy External-DNS using helm

```bash
helm upgrade --install external-dns-internal external-dns \
    --repo https://kubernetes-sigs.github.io/external-dns \
    --namespace dns \
    --create-namespace \
    --values ./helm/external-dns/internal/values.yaml
```

## Dump chart values

```bash
helm show values external-dns --repo https://kubernetes-sigs.github.io/external-dns > ./helm/external-dns/default-values.yaml
```
