# Deploy openldap

OpenLDAP Software is an open source implementation of the Lightweight Directory Access Protocol.

- <https://github.com/jp-gouin/helm-openldap>

## Make sure the Self-signed issuer/ca are deployed

```bash
kubectl apply -f ./helm/cert-manager/selfsigned/
```

## Deploy self-signed certificate

```bash
kubectl apply -f ./helm/openldap/01_tls_cert.yaml
```

## Deploy openldap using helm

```bash
helm upgrade --install openldap openldap-stack-ha \
    --repo https://jp-gouin.github.io/helm-openldap \
    --namespace auth \
    --create-namespace \
    --values ./helm/openldap/values.yaml \
    --values ./helm/openldap/secret-values.yaml
```

## Dump chart values

```bash
helm show values openldap-stack-ha --repo https://jp-gouin.github.io/helm-openldap > ./helm/openldap/default-values.yaml
```
