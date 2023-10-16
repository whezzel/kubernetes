## **Deploy Multus**
Multus allows us to add additional network interfaces to workloads. This can be used to attach workloads to additional networks. The main reason I use it is to allow workloads access to my lan for multicast traffic. Multicast traffic is necessary for specific workloads like homeassistant and esphome to discover new devices on the network.

- https://artifacthub.io/packages/helm/bitnami/multus-cni

**Deploy Helm chart:**
```yaml
helm upgrade --install multus oci://registry-1.docker.io/bitnamicharts/multus-cni \
    --namespace multus \
    --create-namespace
```

**Create and Deploy multus interface definition:**
```bash
cat > ~/repos/k3s/helm/multus/01_cni_conf.yaml <<'EOF'
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
  namespace: multus
spec:
  config: |
    {
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "mode": "bridge",
    	"ipam": {
    		"type": "host-local",
    		"ranges": [
    			[
    				{
    					"subnet": "10.69.50.0/24",
    					"rangeStart": "10.69.50.200",
    					"rangeEnd": "10.69.50.254"
    				}
    			]
    		],
    		"routes": [
          { "dst": "224.0.0.0/24", "gw": "10.69.50.1" },
          { "dst": "255.255.255.255/32", "gw": "10.69.50.1" }
        ]
    	}
    }
EOF
```
```bash
kubectl apply -f ~/repos/k3s/helm/multus/01_cni_conf.yaml
```
