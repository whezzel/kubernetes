# Deploy ingress-nginx

We disabled the traefik ingress controller when deploying k3s, so we will need to deploy a different ingress controller. I chose ingress-inginx.

- <https://kubernetes.github.io/ingress-nginx/deploy>

## Deploy ingress-nginx using helm

```bash
helm upgrade --install nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace nginx \
    --create-namespace \
    --values ./helm/nginx/values.yaml
```

## Dump chart values

```bash
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx > ./helm/nginx/default-values.yaml
```
