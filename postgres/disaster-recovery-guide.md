# CNPG + Longhorn Disaster Recovery Guide
**Rebuilding a PostgreSQL Cluster from Scratch (February 2026)**

Runbook for `sonarr-postgres`.  
Daily backups use CNPG `volumeSnapshot` with `type: bak` (pushed to NFS).  
Full cluster rebuild uses Longhorn-native PVC restore from surviving backups.

### Assumptions
- Nodes and disks are intact (Longhorn replicas exist on disk).
- Longhorn backup target is already configured to NFS.
- Working namespace: `default`.
- Final cluster name: `sonarr-postgres`.

### Step 1: Rebuild Kubernetes + Install Longhorn
1. Reinstall Kubernetes.
2. Install latest Longhorn (Helm or manifest).  
   Longhorn automatically detects all existing volumes and backups.
3. Verify in Longhorn UI → Volumes and Backups (old data present).

### Step 2: Deploy VolumeSnapshot CRDs + Snapshot Controller
#### Deploying CRDs

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
```

#### Deploying Snapshot Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

Verify:
```bash
kubectl get pods -l app.kubernetes.io/name=snapshot-controller -Aw
```

### Step 3: Deploy CNPG Operator

See [Deploying Cloudnative-PG](../helm/cloudnative-pg/README.md)

Verify:
```bash
kubectl get pods -n cnpg -w
```

### Step 4: Restore Longhorn Backup → New PVC (from NFS)
1. Open Longhorn UI.
2. Go to **Backups**.
3. Find the backup for the postgres volume (filter by volume name containing `sonarr-postgres`).
4. Select the desired backup → **Restore**:
   - New volume name: `sonarr-postgres-dr`
   - Size: match original
   - Replicas: 3
5. Wait for restore to complete (volume status becomes ready).
6. Go to **Volumes** → select the new volume → **Create PV/PVC**:
   - Namespace: `seedbox`
   - PVC Name: `sonarr-postgres-dr`

Verify:
```bash
kubectl get pvc sonarr-postgres-dr
```

### Step 5: Deploy Restored CNPG Cluster (PVC Recovery)

Apply:
```bash
kubectl apply -Rf ./postgres/sonarr/
```

Monitor:
```bash
kubectl get cluster sonarr-postgres -w
kubectl get pods -l cnpg.io/cluster=sonarr-postgres -w
```

### Step 6: Create VolumeSnapshotClass (`type: bak` for NFS)
Apply:
```bash
kubectl apply -f ./helm/longhorn/01_snapshot_class.yaml
```

### Step 7: Enable VolumeSnapshot Backups + Scheduled Backup
Patch cluster (likely already done): 
```bash
kubectl patch cluster sonarr-postgres --type=merge -p '
spec:
  backup:
    volumeSnapshot:
      className: longhorn
      online: true
      snapshotOwnerReference: backup
'
```

Apply:
```bash
kubectl apply -f ./postgres/sonarr/02_backups.yaml
```

### Verification
```bash
kubectl get cluster sonarr-postgres -o wide
kubectl get volumesnapshotclass longhorn
kubectl get scheduledbackup cron-sonarr-postgres
```
