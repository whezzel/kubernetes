# [Wiki.js](https://js.wiki/)

The most **powerful** and extensible **open source** Wiki software

Sources:

- https://docs.requarks.io/
- https://docs.requarks.io/install/kubernetes

## Install Wiki.js

Install wiki.js using combination of `helm` and manifests from local computer.

### Apply manifests

```sh
kubectl apply -f wiki-js/
```

### Add the Wiki.js Helm Repository

```sh
helm repo add requarks https://charts.js.wiki
```

### Install helm chart

```sh
helm install wiki-js \
  requarks/wiki \
  --namespace cloud \
  --create-namespace \
  --values ./values.yaml
```

## Uninstall Wiki.js

```sh
helm uninstall -n cloud wiki-js
kubectl delete -f wiki-js/
```

## Upgrade Wiki.js

1. Run *[Uninstall Wiki.js](#uninstall-wikijs)* step.
2. Upgrade the install Wiki.js helm repository.

    ```sh
    helm repo update requarks
    ```

3. Run *[Install helm chart](#install-helm-chart)* step.
