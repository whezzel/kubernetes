# Deploy ingress-nginx

We disabled the traefik ingress controller when deploying k3s, so we will need to deploy a different ingress controller. I chose ingress-inginx.

- <https://kubernetes.github.io/ingress-nginx/deploy>

**Example values.yaml:**

```yaml
cat > ./helm/nginx/values.yaml <<'EOF'
---
controller:
  replicaCount: 5
  service:
    externalTrafficPolicy: "Local"
    loadBalancerIP: 10.69.21.20
    ports:
      http: 80
      https: 443
  extraArgs:
    default-ssl-certificate: "cert-manager/whezzel-com-tls"
  config:
    compute-full-forwarded-for: "true"
    use-forwarded-headers: "false"
    annotations-risk-level: "Critical"
  ingressClassResource:
    default: true
  allowSnippetAnnotations: true
EOF
```

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
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx > ./helm/nginx/temp-values.yaml
```
