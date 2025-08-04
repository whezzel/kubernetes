# Installing Multus on Talos Cluster and Enabling Macvlan Plugin

To install Multus on your Talos cluster and enable the macvlan plugin (since it's not bundled by default in Talos), follow these steps tailored to a manual workflow: download the YAML, edit it locally, and apply it. Talos bundles a set of essential CNI plugins (e.g., bridge, flannel, host-local, loopback, portmap), but macvlan requires manual addition. The official `siderolabs/install-cni` image hasn't been updated beyond alpha versions for Talos 1.10, so we'll use a custom init container in the Multus DaemonSet to download and copy just the macvlan binary from the latest containernetworking/plugins release. This approach uses a privileged init container to handle the extraction and placement into `/opt/cni/bin` on each node, which is writable via bidirectional mount in Talos.

This setup supports amd64, arm64, and arm architectures by dynamically detecting the node's hardware and downloading the appropriate binary.

## Step 1: Download the Multus DaemonSet YAML

Download the standard Multus "thick" DaemonSet YAML file locally:

```bash
curl -O https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

(Alternatively, visit the URL in your browser and save the file as `multus-daemonset-thick.yml`.)

## Step 2: Manually Edit the YAML File

Open `multus-daemonset-thick.yml` in your preferred text editor (e.g., vim, nano, VS Code) and make the following changes:

### Talos-Specific Adjustments

- Locate the `volumes` section under `spec.template.spec` (around line 100-120, depending on the file version).
- Find the volume named `host-run-netns` and change its `hostPath.path` from `/run/netns` to `/var/run/netns` (Talos-specific requirement). It should look like this after editing:

  ```yaml
  - hostPath:
      path: /var/run/netns
    name: host-run-netns
  ```

- Locate the `initContainers` section under `spec.template.spec`.
- Find the init container named `install-multus-binary` and update its `command` to avoid reboot race issues. Replace the existing command with:

  ```yaml
  command:
  - "/usr/src/multus-cni/bin/install_multus"
  - "-d"
  - "/host/opt/cni/bin"
  - "-t"
  - "thick"
  ```

### Add Init Container for Macvlan Plugin

- In the same `initContainers` section, add a new init container entry (e.g., after the `install-multus-binary` container) to dynamically download the latest CNI plugins archive for the node's architecture, extract only the macvlan binary, and copy it to `/opt/cni/bin`. Insert the following YAML block:

  ```yaml
  - name: install-macvlan
    image: alpine:latest
    command:
    - sh
    - -c
    - |
      TAG=$(wget -qO- https://api.github.com/repos/containernetworking/plugins/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') &&
      ARCH=$(uname -m) &&
      case "$ARCH" in
        x86_64) ARCH_SUFFIX="amd64" ;;
        aarch64) ARCH_SUFFIX="arm64" ;;
        armv7l) ARCH_SUFFIX="arm" ;;
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
      esac &&
      echo "Downloading: https://github.com/containernetworking/plugins/releases/download/$TAG/cni-plugins-linux-${ARCH_SUFFIX}-$TAG.tgz" &&
      wget https://github.com/containernetworking/plugins/releases/download/$TAG/cni-plugins-linux-${ARCH_SUFFIX}-$TAG.tgz -O /tmp/cni.tgz &&
      tar -xzf /tmp/cni.tgz -C /tmp ./macvlan &&
      cp /tmp/macvlan /host/opt/cni/bin/macvlan &&
      rm -rf /tmp/cni.tgz /tmp/macvlan
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /host/opt/cni/bin
      name: cnibin
      mountPropagation: Bidirectional
  ```

This init container:

- Uses `alpine:latest` (ensures the latest stable Alpine version; basic commands like `wget`, `tar`, `cp`, `rm`, `grep`, and `sed` are provided via BusyBox and remain stable across versions).
- Dynamically fetches the latest release tag via the GitHub API (no authentication needed; uses only built-in tools).
- Detects the node's architecture with `uname -m` and maps it to the appropriate suffix (amd64, arm64, arm). Errors out if unsupported.
- Prints the download URL for logging/debugging.
- Downloads the latest plugins archive for that architecture.
- Extracts and copies only `macvlan` (static binary, kernel-agnostic).
- Cleans up to avoid leaving files.

The DaemonSet already has the `cnibin` volume defined as a hostPath to `/opt/cni/bin`, so no additional volume is needed.

**Note on Tolerations for Control Plane Nodes**: If you do not want Multus to run on your control plane nodes (to avoid scheduling DaemonSet pods there), locate the `tolerations` section under `spec.template.spec` (around line 150, depending on the file version). It typically looks like this:

```yaml
tolerations:
  - operator: Exists
    effect: NoSchedule
  - operator: Exists
    effect: NoExecute
```

Comment out or remove these lines to prevent the DaemonSet from tolerating NoSchedule and NoExecute taints on control plane nodes.

Save the file after making these edits.

## Step 3: Apply the Edited YAML

Apply the modified DaemonSet to your cluster:

```bash
kubectl apply -f multus-daemonset-thick.yml
```

## Step 4: Verify Installation

- Check DaemonSet pods are running: `kubectl get pods -n kube-system | grep multus`
- SSH is disabled on Talos, but you can use `talosctl` to inspect nodes: `talosctl --nodes <node-ip> ls /opt/cni/bin` (should show `macvlan`).
- Test by creating a `NetworkAttachmentDefinition` for macvlan:

  ```yaml
  ---
  apiVersion: k8s.cni.cncf.io/v1
  kind: NetworkAttachmentDefinition
  metadata:
    name: macvlan-conf
    namespace: kube-system
  spec:
    config: '{
        "cniVersion": "0.3.0",
        "name": "macvlan-conf",
        "type": "macvlan",
        "master": "eth0",
        "mode": "bridge",
        "ipam": {
          "type": "host-local",
          "subnet": "10.69.20.0/24",
          "rangeStart": "10.69.20.200",
          "rangeEnd": "10.69.20.254",
          "routes": [
            { "dst": "224.0.0.0/24" },
            {	"dst": "255.255.255.255/32" }
          ],
          "gateway": "10.69.20.1"
        }
      }'
  ```

  Apply with `kubectl apply -f macvlan-conf.yaml`.

- Attach to a pod via annotation: `k8s.v1.cni.cncf.io/networks: macvlan-conf`

## Notes

- This runs once per node (as an init container in the DaemonSet). If nodes reboot, it re-runs harmlessly.
- The dynamic fetch uses the public GitHub API; rate limiting is unlikely for cluster initialization but possible in high-volume scenarios.
- If your cluster is air-gapped, host the `.tgz` file internally (e.g., in a local registry or ConfigMap) and adjust the `wget` URL in the YAML (remove the dynamic TAG and ARCH logic and hardcode the URL/suffix).
- For GitHub Actions build: You could automate building a custom image (based on Alpine) that embeds the binary and copies it, then push to your registry and reference it in the init container.
- If you need all plugins (not just macvlan), change the tar command in the YAML to `tar -xzf /tmp/cni.tgz -C /host/opt/cni/bin/` (extracts everything directly).
- The plugins will automatically update to the latest available at deployment time; no need to manually check <https://github.com/containernetworking/plugins/releases> unless troubleshooting.
- As of July 2025, the latest CNI plugins version is v1.7.1, and Multus is v4.2.1, but the dynamic script ensures compatibility with future releases.
