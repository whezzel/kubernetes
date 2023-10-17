# **K3s Installation**
I was unable to get multus working with the built-in flannel and CNI plugins. To get around this I disabled the built-in flannel, when deploying k3s, then deploy flannel from the latest manifest. Vanilla flannel also doesn't seem to work with the built in CNI plugins, so I deploy the vanilla version of those too.
## **Preparation**

***To be performed on each node you plan to add to the cluster.***

If you plan to mount nfs shares directly to your workloads, you will need `nfs-utils`:
```bash
pacman -S nfs-utils
```
**Install and enable iscsi**
```bash
pacman -S open-iscsi
systemctl enable --now iscsid.service
```
**Setup CNI plugins for vanilla flannel**
- https://github.com/containernetworking/plugins
```bash
mkdir -p /opt/cni/bin
cd /opt/cni/bin
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
```
**Extract the cni plugins**
```bash
tar -xvf cni-plugins-linux-amd64-v1.3.0.tgz
```

# **Deploy K3s using `k3sup` script**
- https://github.com/alexellis/k3sup

> If k3sup fails due to ssh authentication errors, you probably need to add the `PubkeyAcceptedKeyTypes=+ssh-rsa` option to `/etc/ssh/sshd_config` on each of your nodes.

Here is an example of the script I run to deploy K3s with 3x master nodes and 2x worker nodes. Make sure you adjust all the hostnames and ip addresses to match your environment:
```bash
#!/bin/bash
set -e

#export CHANNEL="v1.27.4+k3s1"
export CHANNEL="latest"
export MASTER_1="archserv01.whezzel.com"
export MASTER_2="archserv02.whezzel.com"
export MASTER_3="archserv03.whezzel.com"
export AGENT_1="archserv04.whezzel.com"
export AGENT_2="archserv05.whezzel.com"
export USER=root

k3sup install \
  --cluster \
  --user $USER \
  --host $MASTER_1 \
  --local-path "$HOME/.kube/config" \
  --merge \
  --context prod \
  --k3s-channel $CHANNEL \
  --print-command \
  --print-config \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--write-kubeconfig-mode 664 --tls-san k3s-api.whezzel.com --tls-san archserv01.whezzel.com --flannel-backend=none --disable-network-policy --disable traefik --disable servicelb'

k3sup join \
  --server \
  --host $MASTER_2 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--write-kubeconfig-mode 664 --tls-san k3s-api.whezzel.com --tls-san archserv01.whezzel.com --flannel-backend=none --disable-network-policy --disable traefik --disable servicelb'

k3sup join \
  --server \
  --host $MASTER_3 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--write-kubeconfig-mode 664 --tls-san k3s-api.whezzel.com --tls-san archserv01.whezzel.com --flannel-backend=none --disable-network-policy --disable traefik --disable servicelb'

k3sup join \
 --server-host archserv01.whezzel.com \
  --host $AGENT_1 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa"

k3sup join \
  --server-host archserv01.whezzel.com \
  --host $AGENT_2 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa"
```

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
  myASN: 64513
  peerASN: 64512
  peerAddress: 10.69.20.2
---
apiVersion: metallb.io/v1beta2
kind: BGPPeer
metadata:
  name: opnsense02
  namespace: metallb
spec:
  myASN: 64513
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

## **Deploy Multus**
Multus allows us to add additional network interfaces to workloads. This can be used to attach workloads to additional networks. The main reason I use it is to allow workloads access to my lan for multicast traffic. Multicast traffic is necessary for specific workloads like homeassistant and esphome to discover new devices on the network.

- https://artifacthub.io/packages/helm/bitnami/multus-cni

**Deploy Helm chart:**
```bash
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

# Deploy kubed
Cert Manager stores the certficates as secrets, and screts are only accessible in the namespace they belong to. Kubed allows us to copy secrets to other namespaces automatically.

- https://appscode.com/products/kubed/v0.12.0/setup/install/

**Deploy kubed using helm:**
```bash
helm upgrade --install kubed kubed \
    --repo https://charts.appscode.com/stable/ \
    --namespace kubed \
    --create-namespace \
    --set apiserver.enabled=false \
    --set config.clusterName=prod
```
### **Setup your secrets and namespaces for syncing:**
- https://appscode.com/products/kubed/latest/guides/config-syncer/intra-cluster/

Annotate the secret you want to sync:
```bash
kubectl annotate secrets -n cert-manager <SECRET_NAME> kubed.appscode.com/sync="app=kubed"
```
and the namespaces we want to sync it to:
```bash
kubectl label namespace <NAMESPACE> app=kubed
```

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


## **Deploy Longhorn**
Longhorn is a distributed storage solution. It allows us to create storage volumes with replicas for resiliency. It allows storage to stay available even if one of your nodes goes down.

- https://longhorn.io/docs/latest/deploy/install/install-with-helm/


**Example values.yaml:**
```bash
cat > ~/repos/k3s/longhorn/values.yaml <<'EOF'
csi:
  kubeletRootDir: /var/lib/kubelet

defaultSettings:
  backupTarget: nfs://archserv02.whezzel.com:/mnt/netstorage/backups/longhorn
  replicaSoftAntiAffinity: false
  replicaZoneSoftAntiAffinity: true
  defaultReplicaCount: 5
  defaultLonghornStaticStorageClass: longhorn
  guaranteedEngineCPU: 0.20
  #defaultDataLocality: disabled
  defaultDataLocality: best-effort
  replicaAutoBalance: best-effort
  orphanAutoDeletion: true

ingress:
  enabled: true
  ingressClassName: nginx
  host: longhorn.whezzel.com
EOF
```

**Deploy longhorn using helm:**
```bash
helm upgrade --install longhorn longhorn \
    --repo https://charts.longhorn.io \
    --namespace longhorn \
    --create-namespace \
    --values ~/repos/k3s/helm/longhorn/values.yaml
```

**Deploy supporting manifests**
```bash
k apply -Rf ~/repos/k3s/longhorn/
```

## **Deploy Nvidia GPU Operator**
- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#install-helm

**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/gpu-operator/values.yaml <<'EOF'
operator:
  defaultRuntime: containerd

driver:
  enabled: false

toolkit:
  enabled: false
EOF
```
You will need to install the Nvidia container runtime available on the AUR. Containerd will auto detect the nvidia runtime:
```bash
yay -S nvidia-container-runtime
```
Scroll down to "Bare-metal/Passthrough with pre-installed drivers and NVIDIA Container Toolkit"
```bash
helm upgrade --install gpu-operator gpu-operator \
    --repo https://helm.ngc.nvidia.com/nvidia \
    --namespace gpu-operator \
    --create-namespace \
    --values ~/repos/k3s/helm/gpu-operator/values.yaml
```

# **Troubeshooting**
## Removing a failed node from kubernetes cluster
**Sometimes you need to remove a failed node from your cluster. This can be completed by running:**
```bash
kubectl delete node <node_name>
```
**Uninstall k3s from node (ssh to failed node):**
```bash
k3s-uninstall.sh
```
**Sometimes files get left behind. I like to manually remove the following paths:**
```bash
/etc/rancher
/var/lib/longhorn
```
## **Remove failed master from etcd cluster**
If this node happens to be a master node, you might also have to remove it from the etcd cluster before you can re-add it.

- https://github.com/k3s-io/k3s/issues/2732#issuecomment-749484037

**Create etcdctl pod for access to etcdctl:**
This has to be run on a master node so it can have access to the etcd database, so a nodeSelector has been added to ensure it runs on a node with etcd access.
```bash
kubectl run --rm --tty --stdin --image docker.io/rancher/coreos-etcd:v3.4.13-amd64 etcdctl --overrides='{"apiVersion":"v1","kind":"Pod","spec":{"hostNetwork":true,"restartPolicy":"Never","securityContext":{"runAsUser":0,"runAsGroup":0},"containers":[{"command":["/bin/sh"],"image":"docker.io/bitnami/etcd:latest","name":"etcdctl","stdin":true,"stdinOnce":true,"tty":true,"volumeMounts":[{"mountPath":"/var/lib/rancher","name":"var-lib-rancher"}]}],"volumes":[{"name":"var-lib-rancher","hostPath":{"path":"/var/lib/rancher","type":"Directory"}}],"nodeSelector":{"node-role.kubernetes.io/etcd":"true"}}}'
```

**List Cluster members:**
```bash
etcdctl --key /var/lib/rancher/k3s/server/tls/etcd/client.key --cert /var/lib/rancher/k3s/server/tls/etcd/client.crt --cacert /var/lib/rancher/k3s/server/tls/etcd/server-ca.crt member list
```
**Remove Cluster member:**
```
etcdctl --key /var/lib/rancher/k3s/server/tls/etcd/client.key --cert /var/lib/rancher/k3s/server/tls/etcd/client.crt --cacert /var/lib/rancher/k3s/server/tls/etcd/server-ca.crt member remove <MEMBER_ID_FROM_PREVIOUS_COMMAND>
```
**Uninstall k3s (ssh into node and run):**
```bash
k3s-uninstall.sh
```
