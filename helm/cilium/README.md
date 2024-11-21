helm upgrade --install cilium cilium \
    --repo https://helm.cilium.io \
    --namespace kube-system \
    --create-namespace \
    --values ~/repos/k3s/helm/cilium/values.yaml
