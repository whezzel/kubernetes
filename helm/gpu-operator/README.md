## **Deploy Nvidia GPU Operator**
- https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html#install-helm

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
Contents of my `values.yaml`
```yaml
operator:
  defaultRuntime: containerd

driver:
  enabled: false

toolkit:
  enabled: false
```
