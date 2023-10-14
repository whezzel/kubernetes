## **Deploy Crowdsec**

Crowdsec is a modern fail2ban

 - https://github.com/crowdsecurity/helm-charts/blob/main/charts/crowdsec/README.md


**Apply supporting manifests:**
```bash
kubectl apply -f ~/repos/k3s/helm/crowdsec
```

**Deploy Crowdsec using helm:**
```bash
helm upgrade --install crowdsec crowdsec \
    --repo https://crowdsecurity.github.io/helm-charts \
    --namespace crowdsec \
    --create-namespace \
    --values ~/repos/k3s/helm/crowdsec/values.yaml
```
