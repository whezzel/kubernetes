## **Deploy Longhorn**
Longhorn is a distributed storage solution. It allows us to create storage volumes with replicas for resiliency. It allows storage to stay available even if one of your nodes goes down.

- https://longhorn.io/docs/latest/deploy/install/install-with-helm/

**Example values.yaml:**
```bash
cat > ~/repos/k3s/longhorn/values.yaml <<'EOF'
csi:
  kubeletRootDir: /var/lib/kubelet

defaultSettings:
  backupTarget: nfs://nas.whezzel.com:/mnt/netstorage/backups/longhorn
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
