## **Deploy External-DNS**

External-DNS tracks svc/ing and creates dns records

 - https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/README.md


**Apply supporting manifests:**
```bash
kubectl apply -f ~/repos/k3s/helm/external-dns/internal
```

**Deploy External-DNS using helm:**
```bash
helm upgrade --install external-dns-internal external-dns \
    --repo https://kubernetes-sigs.github.io/external-dns \
    --namespace dns \
    --create-namespace \
    --values ~/repos/k3s/helm/external-dns/internal/values.yaml
```
