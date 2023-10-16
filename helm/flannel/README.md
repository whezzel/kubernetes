## **Deploy Flannel**

Flannel is a CNI for kubernetes

 - https://github.com/flannel-io/flannel
 - https://github.com/flannel-io/flannel/tree/master/chart

**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/flannel/values.yaml <<'EOF'
---
podCidr: "10.42.0.0/16"
podCidrv6: ""
EOF
```
**Create and apply supporting manifests:**
```bash
cat > ~/repos/k3s/helm/flannel/00_namespace.yaml <<'EOF'
---
apiVersion: v1
kind: Namespace
metadata:
  name: flannel
  labels:
    pod-security.kubernetes.io/enforce: privileged
EOF
```
```bash
kubectl apply -f ~/repos/k3s/helm/flannel/00_namespace.yaml
```

**Deploy Flannel using helm:**
```bash
helm upgrade --install flannel flannel \
    --repo https://flannel-io.github.io/flannel/ \
    --namespace flannel \
    --create-namespace \
    --values ~/repos/k3s/helm/flannel/values.yaml
```
