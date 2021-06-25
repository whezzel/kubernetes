# k3s
Personal collection of Kubernetes deployments and such

## How to modify contents of dynamic PVC

```bash
kubectl -n <namespace> scale --replicas 0 deployment <deployment>
mount -o loop /var/lib/longhorn/replicas/path/to/.img /mnt/temp/
# modify contents #
unmount /mnt/temp
kubectl -n <namespace> scale --replicas 1 deployment <deployment>
```
