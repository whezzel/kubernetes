# Reflector
Reflector is a Kubernetes addon designed to monitor changes to resources (secrets and configmaps) and reflect changes to mirror resources in the same or other namespaces.


```bash
helm upgrade --install reflector reflector \
    --repo https://emberstack.github.io/helm-charts \
    --namespace kube-system
```
