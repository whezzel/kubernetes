## **Deploy Longhorn**
Longhorn is a distributed storage solution. It allows us to create storage volumes with replicas for resiliency. It allows storage to stay available even if one of your nodes goes down.

- https://longhorn.io/docs/latest/deploy/install/install-with-helm/

**Deploy longhorn using helm:**
```bash
helm upgrade --install longhorn longhorn \
    --repo https://charts.longhorn.io \
    --namespace longhorn-system \
    --create-namespace \
    --values ~/repos/k3s/helm/longhorn/values.yaml
```

**Deploy support manifests**
```bash
k apply -Rf ~/repos/k3s/longhorn/01_ingress.yaml
```

**Example values.yaml:**
```
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
  annotations:
    # annotations for authelia
    nginx.ingress.kubernetes.io/auth-method: GET
    nginx.ingress.kubernetes.io/auth-url: http://authelia.auth.svc.cluster.local/api/verify
    nginx.ingress.kubernetes.io/auth-signin: https://authelia.whezzel.com?rm=$request_method
    nginx.ingress.kubernetes.io/auth-response-headers: Remote-User,Remote-Name,Remote-Groups,Remote-Email
    nginx.ingress.kubernetes.io/auth-snippet: |
      proxy_set_header X-Forwarded-Method $request_method;
```
