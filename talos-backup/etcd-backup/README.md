# etcd backups (Talos)

Every 6 hours (`17 */6 * * *`, America/Chicago) a CronJob on a control plane node runs
`talosctl etcd snapshot` against talos01, talos02, talos03 in order and stops at the first
success. The snapshot is written to a scratch emptyDir, encrypted with `age` to the public key
in ConfigMap `etcd-backup-age`, written to nas01, and the plaintext is shredded. Failures send a
Gotify notification.

- Image: `ghcr.io/whezzel/alpine-tools:latest` (age, talosctl). The script is in ConfigMap
  `etcd-backup-script`, so script changes need no image rebuild.
- Storage: nas01 `/mnt/vg1000-lv/backups/etcd`, bind-mounted at `/exports/etcd-backup` (NFSv4 path `/etcd-backup`), exported to the control
  plane IPs only, `all_squash` to uid/gid 1000. PV `talos-backup-etcd-nfs`, PVC `etcd-backups`.
- Layout: `6h/etcd-<UTC timestamp>-<node>.snapshot.age` plus `.sha256` (newest 28 kept) and
  `daily/` (first snapshot of each UTC day, kept 30 days).
- Talos access: `talos-machine-patch.yaml` (KubeTalosAPIAccessConfig) on talos01-03 allows the
  `talos-backup` namespace to use the `os:etcd:backup` role.
- The age private key is kept offline and is never in the cluster.

Snapshots contain every Kubernetes Secret, so keep the export restricted to the control planes.

## Image

talosctl is added in the alpine-tools Dockerfile:

```dockerfile
ARG TALOSCTL_VERSION=v1.14.4
FROM ghcr.io/siderolabs/talosctl:${TALOSCTL_VERSION} AS talosctl
# ...existing FROM and apk add...
COPY --from=talosctl /talosctl /usr/local/bin/talosctl
```

Build for `linux/amd64` and `linux/arm64`. Bump `TALOSCTL_VERSION` on Talos minor upgrades.
If an image-pull failure prevents the script from starting, no alert is sent.

## Install

```bash
kubectl apply -f ./namespaces/talos-backup.yaml
kubectl apply -f ./talos-backup/etcd-backup/00_serviceaccounts.yaml
kubectl -n talos-backup get secret talos-backup-secrets      # created by Talos
kubectl apply -f ./talos-backup/etcd-backup/00_secrets.yaml  # from secret-template.yaml
kubectl apply -f ./talos-backup/etcd-backup/01_configmaps.yaml
kubectl apply -f ./talos-backup/etcd-backup/02_storage.yaml
kubectl -n talos-backup get pvc etcd-backups                 # Bound
kubectl apply -f ./talos-backup/etcd-backup/40_app.yaml      # CronJob is suspended
```

Test, then enable:

```bash
kubectl -n talos-backup create job --from=cronjob/etcd-backup etcd-backup-manual-$(date +%s)
kubectl -n talos-backup logs -f -l app=etcd-backup
kubectl -n talos-backup patch cronjob etcd-backup -p '{"spec":{"suspend":false}}'
```

## Verify a snapshot

On nas01:

```bash
cd /mnt/vg1000-lv/backups/etcd/6h
sha256sum -c etcd-<ts>-<node>.snapshot.age.sha256
```

On the machine holding the private key (`~/documents/age.key`, passphrase-protected; age prompts for the passphrase):

```bash
V=$(mktemp -d)
age -d -i ~/documents/age.key -o "$V/snap" etcd-<ts>-<node>.snapshot.age && ls -l "$V/snap"
shred -fu "$V/snap" && rm -rf "$V"
```

## Restore

Restore uses the official Talos disaster recovery procedure, which covers both a single control plane failure and a full etcd loss: [Talos disaster recovery](https://docs.siderolabs.com/talos/latest/build-and-extend-talos/cluster-operations-and-maintenance/disaster-recovery). The steps below only add the decryption of the snapshot from this backup.

```bash
V=$(mktemp -d)
age -d -i ~/documents/age.key -o "$V/snap" etcd-<ts>-<node>.snapshot.age
talosctl -n <cp> bootstrap --recover-from="$V/snap"
shred -fu "$V/snap" && rm -rf "$V"
```

## Rollback

```bash
kubectl delete namespace talos-backup
kubectl delete pv talos-backup-etcd-nfs    # snapshots stay on nas01
```

Then remove the KubeTalosAPIAccessConfig document from the control plane config.
