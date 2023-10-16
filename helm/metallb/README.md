## **Deploy MetalLB**

MetalLB is a loadbalancer for bare metal kubernetes

 - https://metallb.universe.tf/installation/

**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/metallb/values.yaml <<'EOF'
---
loadBalancerClass: "metallb"
speaker:
  enabled: true
  frr:
    enabled: true

EOF
```

**Create and Deploy Metallb namespace:**
```bash
cat > ~/repos/k3s/helm/metallb/00_namespace.yaml <<'EOF'
---
apiVersion: v1
kind: Namespace
metadata:
  name: metallb
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
EOF
```
```bash
kubectl apply -f ~/repos/k3s/helm/metallb/00_namespace.yaml
```

**Deploy MetalLB using helm:**
```bash
helm upgrade --install metallb metallb \
    --repo https://metallb.github.io/metallb \
    --namespace metallb \
    --create-namespace \
    --values ~/repos/k3s/helm/metallb/values.yaml
```

**Create and Deploy metallb ip address pool:**
```bash
cat > ~/repos/k3s/helm/metallb/01_ipaddresspool.yaml <<'EOF'
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool106952
  namespace: metallb
spec:
  addresses:
  - 10.69.21.0/24

EOF
```
```bash
kubectl apply -f ~/repos/k3s/helm/metallb/01_ipaddresspool.yaml
```

**Create and Deploy metallb bgp peer:**
```bash
cat > ~/repos/k3s/helm/metallb/01_ipaddresspool.yaml <<'EOF'
---
apiVersion: metallb.io/v1beta2
kind: BGPPeer
metadata:
  name: opnsense01
  namespace: metallb
spec:
  myASN: 64514
  peerASN: 64512
  peerAddress: 10.69.20.2
---
apiVersion: metallb.io/v1beta2
kind: BGPPeer
metadata:
  name: opnsense02
  namespace: metallb
spec:
  myASN: 64514
  peerASN: 64512
  peerAddress: 10.69.20.3
EOF
```
```bash
kubectl apply -f ~/repos/k3s/helm/metallb/01_ipaddresspool.yaml
```

**Create and Deploy metallb bgp advertisements:**
```bash
cat > ~/repos/k3s/helm/metallb/03_bgpadvertisement.yaml.yaml <<'EOF'
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: bgpadv
  namespace: metallb
spec:
  ipAddressPools:
  - pool106952
EOF
```
```bash
kubectl apply -f ~/repos/k3s/helm/metallb/03_bgpadvertisement.yaml.yaml
```
