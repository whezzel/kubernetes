## **Deploy Authentik**

authentik is an IdP (Identity Provider) and SSO (single sign on) that is built with security at the forefront of every piece of code, every feature, with an emphasis on flexibility and versatility.

 - https://docs.goauthentik.io/docs/
 - https://docs.goauthentik.io/docs/installation/kubernetes


**Example secrets.yaml**

```bash
cat > ~/repos/k3s/helm/authentik/secrets.yaml <<'EOF'
---
apiVersion: v1
kind: Secret
metadata:
  name: authentik
  namespace: auth
type: Opaque
data:
  AUTHENTIK_POSTGRESQL__PASSWORD: "<ThesIsNotASecurePassword>" #You can generate and encode the password with (echo -n "`openssl rand -base64 36 | tr -d '\n'`" |base64)
  AUTHENTIK_SECRET_KEY: "<PleaseGenerateASecureKey>" #You can generate and encode the secret with (echo -n "`openssl rand -base64 60 | tr -d '\n'`" |base64)
  AUTHENTIK_EMAIL__HOST: smtp-relay-lb.email
  AUTHENTIK_EMAIL__PORT: 25

```
**Deploy Secret**
```bash
k apply -f ~/repos/k3s/helm/authentik/secret.yaml
```

**Example values.yaml:**
```bash
cat > ~/repos/k3s/helm/authentik/values.yaml <<'EOF'
global:
  envFrom:
    - secretRef:
      name: authentik

authentik:
  secret_key: ""
  # This sends anonymous usage-data, stack traces on errors and
  # performance data to authentik.error-reporting.a7k.io, and is fully opt-in
  error_reporting:
    enabled: false

server:
  ingress:
    enabled: true
    hosts:
      - authentik.domain.tld

postgresql:
  enabled: true

redis:
  enabled: true
EOF
```
**Deploy Authentik using helm:**
```bash
helm upgrade --install authentik authentik \
    --repo https://charts.goauthentik.io \
    --namespace auth \
    --values ~/repos/k3s/helm/authentik/values.yaml
```
