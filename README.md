# Deploying kubernetes on talos linux

## Apply Namespaces

```bash
kubectl apply -Rf ./namespaces
```

## Apply node labels

```bash
kubectl apply -Rf ./nodes
```

## Apply BGP configs for cilium

```bash
kubectl apply -f ./helm/cilium
```

## Deploy cert-manager

See [Deploying Cert manager](./helm/cert-manager/README.md)

## Deploy ingress-nginx

See [Deploying ingress-nginx](./helm/nginx/README.md)

## Deploy longhorn

See [Deploying longhorn](./helm/longhorn/README.md)

> [!NOTE]
> Restore critical volumes in Longhorn UI before proceeding. ie. bind, pihole01, pihole02

## Deploy DNS

```bash
kubectl apply -Rf ./dns
```

## Deploy external-dns

See [Deploying External DNS - Internal](./helm/external-dns/internal/README.md)

## Deploy Cloudnative-PG Operator

See [Deploying Cloudnative-PG](./helm/cloudnative-pg/README.md)

## Deploy Keel

See [Deploying Keel](./helm/keel/README.md)

## Deploy Reflector

See [Deploying Reflector](./helm/reflector/README.md)

## Deploy Headlamp

See [Deploying Headlamp](./helm/headlamp/README.md)

## Deploy OpenLDAP

See [Deploying OpenLDAP](./helm/openldap/README.md)

## Deploy Docker-mailserver

See [Deploying Docker Mailserver](./helm/docker-mailserver/README.md)

## Deploy Authelia

See [Deploying Authelia](./helm/authelia/README.md)

## Deploy Crowdsec

See [Deploying Crowdsec](./helm/crowdsec/README.md)
