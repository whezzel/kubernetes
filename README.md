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
systemctl enable --now iscsi.service
```
If you plan to use a Nvidia gpu in your workloads, you will need to install the Nvidia container runtime available on the AUR. Containerd will auto detect the nvidia runtime:
```bash
yay -S nvidia-container-toolkit nvidia-container-runtime
```
**Setup CNI plugins for vanilla flannel**
- https://github.com/containernetworking/plugins
```bash
mkdir -p /opt/cni/bin
cd /opt/cni/bin
```
**For amd64:**
```bash
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
```
**For arm64:**
```bash
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-arm64-v1.2.0.tgz
```
**Extract the cni plugins**
```bash
tar -xvf cni-plugins-linux-{amd64|arm64}-v1.2.0.tgz
```

# **Deploy K3s using `k3sup` script**
- https://github.com/alexellis/k3sup

> If k3sup fails due to ssh authentication errors, you probably need to add the `PubkeyAcceptedKeyTypes=+ssh-rsa` option to `/etc/ssh/sshd_config` on each of your nodes.

Here is an example of the script I run to deploy K3s with 3x master nodes and 2x worker nodes. Make sure you adjust all the hostnames and ip addresses to match your environment:
```bash
#!/bin/bash
set -e

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
  --k3s-extra-args '--write-kubeconfig-mode 664 --tls-san k3s-api.whezzel.com --tls-san archserv01.whezzel.com --flannel-backend=none --disable-network-policy --node-ip 10.69.2.20,2600:1700:3c00:635f:2::20 --cluster-cidr 10.42.0.0/16,2001:cafe:42::/56 --service-cidr 10.43.0.0/16,2001:cafe:43::1/112'

k3sup join \
  --server \
  --host $MASTER_2 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--write-kubeconfig-mode 664 --tls-san k3s-api.whezzel.com --tls-san archserv01.whezzel.com --flannel-backend=none --disable-network-policy --node-ip 10.69.2.10,2600:1700:3c00:635f:2::10 --cluster-cidr 10.42.0.0/16,2001:cafe:42::/56 --service-cidr 10.43.0.0/16,2001:cafe:43::1/112'

k3sup join \
  --server \
  --host $MASTER_3 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--write-kubeconfig-mode 664 --tls-san k3s-api.whezzel.com --tls-san archserv01.whezzel.com --flannel-backend=none --disable-network-policy --node-ip 10.69.2.2,2600:1700:3c00:635f:2::2 --cluster-cidr 10.42.0.0/16,2001:cafe:42::/56 --service-cidr 10.43.0.0/16,2001:cafe:43::1/112'

k3sup join \
 --server-host archserv01.whezzel.com \
  --host $AGENT_1 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--node-ip 10.69.2.3,2600:1700:3c00:635f:2::3'

k3sup join \
  --server-host archserv01.whezzel.com \
  --host $AGENT_2 \
  --user $USER \
  --server-user $USER \
  --server-host $MASTER_1 \
  --k3s-channel $CHANNEL \
  --print-command \
  --ssh-key "/home/zach/.ssh/root.id_rsa" \
  --k3s-extra-args '--node-ip 10.69.2.4,2600:1700:3c00:635f:2::4'
```

## **Deploy Flannel**
- https://github.com/flannel-io/flannel

**Download latest manifest:**
```bash
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
Edit the manifest we just downloaded. Find the definition for `net-conf.json` (around line 90 in v0.21.2). Change the ip subnets to match the subnets you selected when running the k3sup script above.

Here is an example of mine. I have enabled IPv6:
```yaml
  net-conf.json: |
    {
      "Network": "10.42.0.0/16",
      "Backend": {
        "Type": "vxlan"
      },
      "EnableIPv6": true,
      "IPv6Network": "2001:cafe:42:0::/56"
    }
```

**Deploy this manifest**
```bash
kubectl deploy ./kube-flannel.yml
```

## **Deploy Multus**
Multus allows us to add additional network interfaces to workloads. This can be used to attach workloads to additional networks. The main reason I use it is to allow workloads access to my lan for multicast traffic. Multicast traffic is necessary for specific workloads like homeassistant and esphome to discover new devices on the network.
- https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/quickstart.md

**Clone the multus repo:**
```bash
git clone https://github.com/k8snetworkplumbingwg/multus-cni.git && cd multus-cni
```
**Deploy multus manifest:**
```bash
kubectl apply -f ~/repos/k3s/multus-cni/deployments/multus-daemonset-thick.yml
```
**Deploy multus interface definition:**
```bash
kubectl apply -f ~/repos/k3s/default/01_cni_conf.yaml
```
**Here is an example of my interface definition. It only has routes for multicast traffic. Adjust as necessary:**
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "10.69.2.0/23",
        "rangeStart": "10.69.3.1",
        "rangeEnd": "10.69.3.254",
        "routes": [
          {
            "dst": "224.0.0.0/24"
          }
        ],
        "gateway": "10.69.2.1"
      }
    }'

```

## **Modify traefik deployment**
Certain services only expose a https port. For those services you either need to add a valid cert to the service, or you need to tell traefik not to verify self-signed certs. I decided to not verify self-signed certs (this is a security risk).

**Edit traefik deployment:**
```bash
kubectl edit -n kube-system deployments traefik
```
**Add the following option to the args section (around line 50). The leading hyphen is required:**
```
- --serverstransport.insecureskipverify=true
```
## **Modify traefik service**
By default, traefik doesn't pass the client IP to backend services, so in logs you only see the internal k8s IPs. Setting the `externalTrafficPolicy` to `local` gets traefik to pass the client ip to backend services.
```bash
kubectl edit -n kube-system service traefik
```

## **Deploy Cert Manager**

Cert Manager obviously manages our certificates. I use it to request and automatically renew LetsEncrypt certs for my domain.

 - https://cert-manager.io/docs/installation/helm/

**Add the Cert Manager repo to helm, and update your repo list:**
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```
**Deploy Cert Manager using helm:**
```bash
helm upgrade --install cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true \
    --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
```
**Apply your issuers, and certs from local manifests:**
```bash
kubectl apply -f cert-manager
```

# Deploy kubed
Cert Manager stores the certficates as secrets, and screts are only accessible in the namespace they belong to. Kubed allows us to copy secrets to other namespaces automatically.
- https://appscode.com/products/kubed/v0.12.0/setup/install/

**Add the kubed repo to helm, and update your repo list:**
```bash
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
```
**Deploy kubed using helm:**
```
helm upgrade --install kubed \
    appscode/kubed \
    --namespace kube-system \
    --set apiserver.enabled=false \
    --set config.clusterName=prod
```
### **Setup your secrets and namespaces for syncing:**
- https://appscode.com/products/kubed/latest/guides/config-syncer/intra-cluster/

Annotate the secret you want to sync:
```bash
kubectl annotate secrets -n cert-manager whezzel.com-tls kubed.appscode.com/sync="app=kubed"
```
and the namespaces we want to sync it to:
```bash
kubectl label namespace homeassistant app=kubed
```

## **Deploy keel.sh**
Manually updating workloads is annoying, but keel.sh allows us to automate that.
- https://keel.sh/docs/#deploying-with-helm

**Add the keel.sh repo to helm, and update your repo list:**
```bash
helm repo add keel https://charts.keel.sh
helm repo update
```
**Deploy keel.sh using helm:**
```bash
helm upgrade --install keel \
    keel/keel \
    --namespace=keel \
    --create-namespace \
    --set "nodeSelector\.kubernetes\.io\/arch"=amd64 \
    --values ~/repos/k3s/keel/values.yaml
```

## **Deploy Longhorn**
Longhorn is a distributed storage solution. It allows us to create storage volumes with replicas for resiliency. It allows storage to stay available even if one of your nodes goes down.
- https://longhorn.io/docs/latest/deploy/install/install-with-helm/

**Add the longhorn repo to helm, and update your repo list:**
```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
```
**Deploy longhorn using helm:**
```bash
helm upgrade --install longhorn \
    longhorn/longhorn \
    --namespace longhorn-system \
    --create-namespace \
    --values ~/repos/k3s/longhorn/values.yaml
```
**Deploy ingress for longhorn so you can access the webui**
```bash
k apply -Rf ~/repos/k3s/longhorn/01_ingress.yaml
```
## **Deploy traefik middlewares**
Traefik middlewares are neccessary for things like automatically redirecting http traffic to https endpoints.
```bash
kubectl apply manifests in kube-system namespace
```
## **Deploy Nvidia GPU Operator**
- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#install-helm

Scroll down to "Bare-metal/Passthrough with pre-installed drivers and NVIDIA Container Toolkit"
```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm upgrade --install --wait gpu-operator \
     -n gpu-operator --create-namespace \
      nvidia/gpu-operator -f gpu-operator/values.yaml
```
Contents of my `values.yaml`
```yaml
operator:
  defaultRuntime: containerd

driver:
  enabled: false

toolkit:
  enabled: false
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
