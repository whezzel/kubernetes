# Deploy Cert Manager

Cert Manager obviously manages our certificates. I use it to request and automatically renew LetsEncrypt certs for my domain.

- <https://cert-manager.io/docs/installation/helm>

## Deploy Cert Manager using helm

```bash
helm upgrade --install cert-manager cert-manager \
    --repo https://charts.jetstack.io \
    --namespace cert-manager \
    --create-namespace \
    --values ./helm/cert-manager/values.yaml
```

## Apply your issuers, and certs from local manifests

```bash
kubectl apply -Rf ./helm/cert-manager
```

## Dump chart values

```bash
helm show values cert-manager --repo https://charts.jetstack.io > ./helm/cert-manager/temp-values.yaml
```
