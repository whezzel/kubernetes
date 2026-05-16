# Deploy Crowdsec

Crowdsec is a modern fail2ban

- <https://github.com/crowdsecurity/helm-charts/blob/main/charts/crowdsec/README.md>

## Apply secrets

```bash
kubectl apply -f ./helm/crowdsec/00_secrets.yaml
```

## Deploy Crowdsec using helm

```bash
helm upgrade --install crowdsec crowdsec \
    --repo https://crowdsecurity.github.io/helm-charts \
    --namespace crowdsec \
    --create-namespace \
    --values ./helm/crowdsec/values.yaml
```

## Dump chart values

```bash
helm show values crowdsec --repo https://crowdsecurity.github.io/helm-charts > ./helm/crowdsec/default-values.yaml
```

## Remove extra machines from lapi

```bash
for i in `cscli machines list|grep "crowdsec-agent-"|cut -d" " -f2`; do cscli machines delete $i; done
```

## Register new machine with lapi

On the machine you want to register with the lapi, run the following command:

```bash
cscli lapi register --machine `hostname | cut -d. -f1` --url https://crowdsec-api.whezzel.com/
```

## Verify new machine on lapi

```bash
cscli machines validate <machine-name>
```
