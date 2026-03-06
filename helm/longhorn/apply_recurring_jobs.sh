#!/bin/bash
# Script to apply the recurring job group 'backups' to existing Longhorn volumes

# List all PVCs using the 'longhorn' StorageClass and extract volume names
kubectl get pvc -A -o json | jq -r '.items[] | select(.spec.storageClassName=="longhorn") | [.metadata.namespace, .metadata.name, .spec.volumeName] | join(",")' | while IFS=',' read -r ns pvc_name volume_name; do
    if [ -n "$volume_name" ]; then
        echo "Processing volume: $volume_name (PVC: $pvc_name in $ns)"
        # Apply the recurring job group label
        kubectl -n longhorn label volume "$volume_name" \
          recurring-job-group.longhorn.io/backups=enabled \
          --overwrite
        kubectl -n longhorn label volume "$volume_name" \
          recurring-job-group.longhorn.io/default=enabled \
          --overwrite
    else
        echo "Skipping PVC $pvc_name in $ns - no volume name found"
    fi
done

echo "Done applying recurring job group 'backups' to existing volumes."
