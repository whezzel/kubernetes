# Deploy docker-mailserver

This chart deploys [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver) into a Kubernetes cluster. docker-mailserver is a production-ready, fullstack mail server that supports SMTP, IMAP, LDAP, Anti-spam, Anti-virus, etc.). Just as importantly, it is designed to be simple to install and configure.

- <https://github.com/docker-mailserver/docker-mailserver-helm/tree/master/charts/docker-mailserver>

## Apply secrets

```bash
kubectl apply -f ./helm/docker-mailserver/00_secrets.yaml
```

## Deploy docker-mailserver using helm

```bash
helm upgrade --install docker-mailserver docker-mailserver \
    --repo https://docker-mailserver.github.io/docker-mailserver-helm \
    --namespace=email \
    --create-namespace \
    --values ./helm/docker-mailserver/values.yaml \
    --values ./helm/docker-mailserver/secret-values.yaml
```

## Dump chart values

```bash
helm show values docker-mailserver --repo https://docker-mailserver.github.io/docker-mailserver-helm > ./helm/docker-mailserver/temp-values.yaml
```

## Generate new client secret

```bash
k exec -it -n $(kubectl get pod --all-namespaces -l app=authelia -o jsonpath="{.items[0].metadata.namespace}") $(kubectl get -n auth pod -l app=authelia -o jsonpath="{.items[0].metadata.name}") -- authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986
```
