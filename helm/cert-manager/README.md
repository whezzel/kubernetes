## **Deploy Cert Manager**

Cert Manager obviously manages our certificates. I use it to request and automatically renew LetsEncrypt certs for my domain.

 - https://cert-manager.io/docs/installation/helm/


**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/cert-manager/values.yaml <<'EOF'
installCRDs: true
dns01RecursiveNameservers: "8.8.8.8:53,1.1.1.1:53"
dns01RecursiveNameserversOnly: true
EOF
```
**Deploy Cert Manager using helm:**
```bash
helm upgrade --install cert-manager cert-manager \
    --repo https://charts.jetstack.io \
    --namespace cert-manager \
    --create-namespace \
    --values ~/repos/k3s/helm/cert-manager/values.yaml
```
**Apply your issuers, and certs from local manifests:**
```bash
kubectl apply -f ~/repos/k3s/helm/cert-manager
```
