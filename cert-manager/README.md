# Install kubed
# https://appscode.com/products/kubed/v0.12.0/setup/install/
# https://rimusz.net/lets-encrypt-wildcard-certs-in-kubernetes
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install kubed appscode/kubed -n kube-system --set apiserver.enabled=false --set config.clusterName=prod
# Uninstall Kubed
helm uninstall -n kube-system kubed

# Annotate Cert Secret for sync
kubectl annotate secrets -n cert-manager <cert-secret-name> kubed.appscode.com/sync="app=kubed"

# Label Namespaces you want to sync to
 kubectl label namespace <namespace> app=kubed