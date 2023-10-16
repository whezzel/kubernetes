## **Deploy keel.sh**
Manually updating workloads is annoying, but keel.sh allows us to automate that.

- https://keel.sh/docs/#deploying-with-helm

**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/keel/values.yaml <<'EOF'
webhook:
  enabled: true
  endpoint: "http://nodered.homeassistant/hooks/ndN656rVjA6E5V26nxXgGmRHo99Cm7wg"
nodeSelector:
  kubernetes.io/arch: amd64
EOF
```
**Deploy keel.sh using helm:**
```bash
helm upgrade --install keel keel \
    --repo https://charts.keel.sh \
    --namespace=keel \
    --create-namespace \
    --values ~/repos/k3s/helm/keel/values.yaml
```
