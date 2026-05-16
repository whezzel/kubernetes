# Deploy authelia

Authelia is an open-source authentication and authorization server providing two-factor authentication and single sign-on (SSO) for your applications via a web portal. It acts as a companion for reverse proxies by allowing, denying, or redirecting requests.

- <https://www.authelia.com/>
- <https://github.com/authelia/authelia>
- <https://charts.authelia.com/>

## Apply secrets

```bash
kubectl apply -f ./helm/authelia/00_secrets.yaml
```

## Deploy authelia using helm

```bash
helm upgrade --install authelia authelia \
    --repo https://charts.authelia.com \
    --namespace auth \
    --create-namespace \
    --values ./helm/authelia/values.yaml
```

## Dump chart values

```bash
helm show values authelia --repo https://charts.authelia.com > ./helm/authelia/default-values.yaml
```
