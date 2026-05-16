# [Prometheus](https://prometheus.io/)

Prometheus is an open-source monitoring and alerting toolkit designed to collect, store, and query metrics as time-series data. It is widely used for monitoring applications, systems, and services, particularly in cloud-native environments. Prometheus was originally developed at SoundCloud and later became a Cloud Native Computing Foundation (CNCF) project.

- https://github.com/prometheus-community/helm-charts
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

## Deploy Prometheus using Helm

```sh
helm upgrade --install prometheus kube-prometheus-stack \
    --repo https://prometheus-community.github.io/helm-charts \
    --namespace prometheus \
    --create-namespace \
    --values ./helm/prometheus/values.yaml
```

## Deploy supporting manifests

```sh
kubectl apply -Rf ./helm/prometheus/
```

## Dump chart values

```bash
helm show values kube-prometheus-stack --repo https://prometheus-community.github.io/helm-charts > ./helm/prometheus/default-values.yaml
```

## Post-Deploy Validation Checklist

Run this checklist after `helm upgrade --install` to confirm Prometheus is scraping expected targets.

<details>
<summary><h3>1. Kubernetes Health Checks</h3></summary>

1. Confirm core monitoring pods are running.

    ```bash
    kubectl -n prometheus get pods -o wide
    ```

    Pass:

    - Prometheus pod is `Running`.
    - Operator pod is `Running`.
    - Node exporter DaemonSet pods are `Running` on all nodes.

2. Confirm node exporter DaemonSet coverage.

    ```bash
    kubectl -n prometheus get ds prometheus-prometheus-node-exporter
    ```

    Pass:

    - `DESIRED`, `CURRENT`, `READY`, and `AVAILABLE` match cluster node count.

3. Confirm Talos metrics service + EndpointSlice exist.

    ```bash
    kubectl -n kube-system get svc talos-metrics
    kubectl -n kube-system get endpointslice -l kubernetes.io/service-name=talos-metrics
    ```

    Pass:

    - Service exists on port `9100`.
    - EndpointSlice exists and includes all expected node IPs.

4. Confirm ServiceMonitors are present.

    ```bash
    kubectl -n prometheus get servicemonitor
    ```

    Pass:

    - Includes expected monitors such as node exporter and Talos monitor(s).

</details>

<details>
<summary><h3>2. Prometheus API Reachability</h3></summary>

Port-forward Prometheus UI/API:

```bash
kubectl -n prometheus port-forward svc/prometheus-operated 9090:9090
```

Then open `http://127.0.0.1:9090` and run the PromQL checks below.

</details>

<details>
<summary><h3>3. PromQL Validation Checks</h3></summary>

1. Verify active scrape jobs.

    ```promql
    count by (job) (up)
    ```

    Pass:

    - Returns non-empty series.
    - In this cluster, expected jobs include:
        `apiserver`, `kubelet`, `node-exporter`, `kube-state-metrics`, `prometheus-kube-prometheus-operator`, `prometheus-kube-prometheus-alertmanager`, `prometheus-kube-prometheus-prometheus`, and `telegraf-external`.

2. Verify node exporter targets.

    ```promql
    count(up{job="node-exporter"} == 1)
    ```

    Pass:

    - Equals node count (currently `8`).

3. Verify control-plane leader election (controller manager).

    ```promql
    sum(leader_election_master_status{job="kube-controller-manager",name="kube-controller-manager"})
    ```

    Pass:

    - Equals `1`.

4. Verify control-plane leader election (scheduler).

    ```promql
    sum(leader_election_master_status{job="kube-scheduler",name="kube-scheduler"})
    ```

    Pass:

    - Equals `1`.

5. Verify scheduler metrics exist.

    ```promql
    count({job="kube-scheduler"})
    ```

    Pass:

    - Greater than `0`.

6. Verify etcd-related metrics path used by this cluster.

    ```promql
    count({__name__=~"etcd_.*"})
    ```

    Pass:

    - Greater than `0`.

    > Note:
    > - On this cluster, `etcd_*` series are exposed via `job="apiserver"` (API server etcd client metrics).
    > - `job="kube-etcd"` may be absent or disabled depending on Talos/control-plane exposure.

7. Verify etcd request activity and errors from apiserver.

    ```promql
    sum(rate(etcd_requests_total{job="apiserver"}[5m]))
    sum(rate(etcd_request_errors_total{job="apiserver"}[5m]))
    ```

    Pass:

    - Requests rate is non-zero during activity.
    - Errors rate is near zero in healthy state.

8. Verify etcd request latency (p99) from apiserver metrics.

    ```promql
    histogram_quantile(
    	0.99,
    	sum by (le) (rate(etcd_request_duration_seconds_bucket{job="apiserver"}[5m]))
    )
    ```

    Pass:

    - Returns numeric value.

9. Verify no down targets.

    ```promql
    sum(up == 0)
    ```

    Pass:

    - Equals `0`.

</details>

<details>
<summary><h3>4. Expected Outputs (This Cluster Baseline)</h3></summary>

Use these as quick sanity checks. Small fluctuations are normal for rate/latency queries.

1. `count(up{job="node-exporter"} == 1)`

   - Expected: `8`

2. `sum(leader_election_master_status{job="kube-controller-manager",name="kube-controller-manager"})`

   - Expected: `1`

3. `sum(leader_election_master_status{job="kube-scheduler",name="kube-scheduler"})`

   - Expected: `1`

4. `count({job="kube-scheduler"})`

   - Expected: greater than `0`

5. `count({__name__=~"etcd_.*"})`

   - Expected: approximately `14799` (may vary with version and scrape state)

6. `count by (job) ({__name__=~"etcd_.*"})`

   - Expected: `apiserver` only

7. `sum(up == 0)`

   - Expected: `0`

8. `count by (job) (up)`

   - Expected jobs include:
    `apiserver`, `kubelet`, `node-exporter`, `kube-state-metrics`, `prometheus-kube-prometheus-operator`, `prometheus-kube-prometheus-alertmanager`, `prometheus-kube-prometheus-prometheus`, `telegraf-external`

9. `count(count by (__name__) ({job="node-exporter", instance=~"10\\.3\\.20\\.(11|12|13):.*"}))`

   - Expected: non-zero (represents metric-name coverage on control-plane nodes)

</details>

<details>
<summary><h3>5. Optional Troubleshooting Queries</h3></summary>

Show all `etcd_*` metrics by job:

```promql
count by (job) ({__name__=~"etcd_.*"})
```

Show node-exporter metric-name count on control-plane nodes:

```promql
count(count by (__name__) ({job="node-exporter", instance=~"10\\.3\\.20\\.(11|12|13):.*"}))
```

</details>

<details>
<summary><h3>6. Re-apply Talos Metrics Discovery (if needed)</h3></summary>

If Talos machine metrics disappear (missing EndpointSlice or wrong addresses), re-apply:

```bash
kubectl apply -f helm/prometheus/01_talos-metrics-service-endpoints.yaml
```

</details>

## Uninstall Helm Chart

```bash
helm uninstall -n prometheus prometheus
```

CRDs created by this chart are not removed by default and should be manually cleaned up:

```bash
k delete crd alertmanagerconfigs.monitoring.coreos.com
k delete crd alertmanagers.monitoring.coreos.com
k delete crd podmonitors.monitoring.coreos.com
k delete crd probes.monitoring.coreos.com
k delete crd prometheusagents.monitoring.coreos.com
k delete crd prometheuses.monitoring.coreos.com
k delete crd prometheusrules.monitoring.coreos.com
k delete crd scrapeconfigs.monitoring.coreos.com
k delete crd servicemonitors.monitoring.coreos.com
k delete crd thanosrulers.monitoring.coreos.com
```
