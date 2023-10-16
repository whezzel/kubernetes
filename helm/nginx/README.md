## **Deploy ingress-nginx**
We disabled the traefik ingress controller when deploying k3s, so we will need to deploy a different ingress controller. I chose ingress-inginx.

 - https://kubernetes.github.io/ingress-nginx/deploy/

**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/nginx/values.yaml <<'EOF'
---
controller:
  replicaCount: 5
  service:
    externalTrafficPolicy: "Local"
    ports:
      http: 80
      https: 443
  extraArgs:
    default-ssl-certificate: "cert-manager/whezzel.com-tls"
  config:
    compute-full-forwarded-for: "false"
    use-forwarded-headers: "true"
  ingressClassResource:
    default: true
  allowSnippetAnnotations: true
EOF
```

**Deploy ingress-nginx using helm:**
```bash
helm upgrade --install nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace nginx \
    --create-namespace \
    --values ~/repos/k3s/helm/nginx/values.yaml
```
