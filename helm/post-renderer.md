# Helm Dual-Stack Post-Renderer Plugin

Adds dual-stack (`PreferDualStack` + `IPv4`/`IPv6`) settings to every Kubernetes `Service` rendered by Helm.

Works with **Helm 4** (required — Helm 4 only accepts post-renderers as plugins).

## What it does

For every manifest with `kind: Service`, the plugin injects:

```yaml
spec:
  ipFamilyPolicy: PreferDualStack
  ipFamilies:
    - IPv4
    - IPv6
```

All other resources are left unchanged.

## Installation

```bash
# Create plugin directory
mkdir -p ~/.local/share/helm/plugins/dualstack

# Create the script
cat > ~/.local/share/helm/plugins/dualstack/dualstack.sh << 'EOF'
#!/bin/bash
yq -y '
  if .kind == "Service" then
    .spec.ipFamilyPolicy = "PreferDualStack" |
    .spec.ipFamilies = ["IPv4", "IPv6"]
  else
    .
  end
'
EOF

chmod +x ~/.local/share/helm/plugins/dualstack/dualstack.sh

# Create plugin metadata (Helm 4 format)
cat > ~/.local/share/helm/plugins/dualstack/plugin.yaml << 'EOF'
apiVersion: v1
type: postrenderer/v1
name: dualstack
version: 0.1.0
runtime: subprocess
runtimeConfig:
  platformCommand:
    - command: ${HELM_PLUGIN_DIR}/dualstack.sh
EOF
```

Verify:

```bash
helm plugin list
```

You should see `dualstack` with type related to postrenderer.

## Usage

```bash
helm upgrade --install <release> <chart> \
  -n <namespace> \
  -f values.yaml \
  --post-renderer dualstack
```

Example (Authelia):

```bash
helm upgrade --install authelia authelia \
  --repo https://charts.authelia.com \
  --namespace auth \
  --create-namespace \
  --values ./helm/authelia/values.yaml \
  --post-renderer dualstack
```

## Requirements

- Helm 4+
- `yq` (Python version that supports `yq -y`, or adjust the script for Go `yq`)

## Notes

- The plugin processes multi-document YAML from Helm.
- It only modifies `Service` objects.
- Safe to use on charts that already set dual-stack fields (it will overwrite them with `PreferDualStack`).
- To change the policy (e.g. to `RequireDualStack`), edit the script and re-run the Helm command.
