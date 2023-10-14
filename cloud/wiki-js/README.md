## **Deploy WikiJS**

The most powerful and extensible open source Wiki software.

- https://docs.requarks.io/
- https://docs.requarks.io/install/kubernetes

**Deploy Manifests to support helm chart:**
```bash
kubectl apply -Rf ~/repos/k3s/cloud/wiki-js
```

**Deploy Wiki JS using helm:**
```bash
helm upgrade --install wiki-js wiki \
    --repo https://charts.js.wiki \
    --namespace cloud \
    --create-namespace \
    --values ~/repos/k3s/cloud/wiki-js/values.yaml
```
