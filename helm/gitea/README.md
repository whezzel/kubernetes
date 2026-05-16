# Deploy gitea

Gitea is a community managed lightweight code hosting solution written in Go. It is published under the MIT license.

- <https://gitea.com/gitea/helm-chart/src/branch/main/README.md>

**Example values.yaml:**

```bash
cat > ./helm/gitea/values.yaml <<'EOF'
---
EOF
```

## Deploy gitea using helm

```bash
helm upgrade --install gitea gitea \
    --repo https://dl.gitea.com/charts \
    --namespace gitea \
    --create-namespace \
    --values ./helm/gitea/values.yaml
```

## Dump chart values

```bash
helm show values gitea --repo https://dl.gitea.com/charts > ./helm/gitea/default-values.yaml
```
