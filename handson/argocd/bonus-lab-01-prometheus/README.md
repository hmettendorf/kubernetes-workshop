# Bonus Lab 1: Prometheus Metrics for Argo CD

## Overview

Learn how to monitor Argo CD with Prometheus and understand key GitOps metrics.

**Duration:** 45 minutes

**Learning Objectives:**
- Enable Argo CD metrics
- Deploy Prometheus to monitor Argo CD
- Understand key Argo CD metrics
- Query metrics with PromQL
- Create alerts for sync failures
- Visualize GitOps health

---

## Prerequisites

- Completed Labs 1-3
- Basic understanding of Prometheus
- Applications deployed in Argo CD

---

## What Metrics Does Argo CD Expose?

Argo CD components expose various Prometheus metrics:

**Application Controller Metrics:**
- `argocd_app_info` - Application information
- `argocd_app_sync_total` - Total number of syncs
- `argocd_app_health_status` - Current health status
- `argocd_app_sync_status` - Current sync status
- `argocd_app_reconcile_count` - Reconciliation attempts

**API Server Metrics:**
- `argocd_api_server_requests_total` - API request count
- `argocd_api_server_request_duration_seconds` - Request latency

**Repo Server Metrics:**
- `argocd_git_request_total` - Git operation count
- `argocd_git_request_duration_seconds` - Git operation duration

---

## Step 1: Enable Argo CD Metrics

### 1.1 Verify Metrics Endpoints

Argo CD metrics are enabled by default. Let's verify:

```bash
# Port forward to application controller metrics
kubectl port-forward -n argocd svc/argocd-metrics 8082:8082 &

# Check metrics endpoint
curl http://localhost:8082/metrics | head -20
```

You should see Prometheus-formatted metrics.

### 1.2 Check All Metrics Endpoints

```bash
# List all Argo CD services
kubectl get svc -n argocd

# You should see:
# - argocd-metrics (application controller)
# - argocd-server-metrics (API server)
# - argocd-repo-server-metrics (repo server)
```

### 1.3 View Sample Metrics

```bash
# Application controller metrics
curl http://localhost:8082/metrics | grep argocd_app_

# Count total applications
curl -s http://localhost:8082/metrics | grep "argocd_app_info{" | wc -l
```

---

## Step 2: Deploy Prometheus

### 2.1 Create Namespace

```bash
kubectl create namespace monitoring
```

### 2.2 Deploy Prometheus

We'll use a simple Prometheus deployment for monitoring:

Create `prometheus-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    scrape_configs:
    - job_name: 'argocd-metrics'
      static_configs:
      - targets:
        - argocd-metrics.argocd.svc.cluster.local:8082
        labels:
          component: application-controller

    - job_name: 'argocd-server-metrics'
      static_configs:
      - targets:
        - argocd-server-metrics.argocd.svc.cluster.local:8083
        labels:
          component: api-server

    - job_name: 'argocd-repo-server-metrics'
      static_configs:
      - targets:
        - argocd-repo-server.argocd.svc.cluster.local:8084
        labels:
          component: repo-server
```

### 2.3 Deploy Prometheus Server

Create `prometheus-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  type: ClusterIP
  ports:
  - port: 9090
    targetPort: 9090
  selector:
    app: prometheus
```

### 2.4 Apply Prometheus Resources

```bash
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
```

### 2.5 Verify Prometheus Deployment

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Wait for the Prometheus pod to be Running.

---

## Step 3: Access Prometheus UI

### 3.1 Port Forward to Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

### 3.2 Open Prometheus UI

Open your browser to: `http://localhost:9090`

### 3.3 Verify Targets

1. Click **Status** → **Targets**
2. You should see three targets:
   - argocd-metrics (application controller)
   - argocd-server-metrics
   - argocd-repo-server-metrics
3. All should show as **UP**

---

## Step 4: Explore Argo CD Metrics

### 4.1 Application Status Metrics

In Prometheus UI, go to **Graph** and try these queries:

**Count applications by sync status:**
```promql
count by (sync_status) (argocd_app_info)
```

**Count applications by health status:**
```promql
count by (health_status) (argocd_app_info)
```

**List all applications:**
```promql
argocd_app_info
```

### 4.2 Sync Metrics

**Total syncs by application:**
```promql
argocd_app_sync_total
```

**Sync rate (syncs per second):**
```promql
rate(argocd_app_sync_total[5m])
```

**Failed syncs:**
```promql
argocd_app_sync_total{phase="Failed"}
```

### 4.3 Reconciliation Metrics

**Reconciliation count:**
```promql
argocd_app_reconcile_count
```

**Reconciliation rate:**
```promql
rate(argocd_app_reconcile_count[5m])
```

### 4.4 Git Operation Metrics

**Git request duration:**
```promql
argocd_git_request_duration_seconds
```

**Git request rate:**
```promql
rate(argocd_git_request_total[5m])
```

---

## Step 5: Create Useful Dashboards

### 5.1 Application Health Overview

Create a query to show unhealthy applications:

```promql
argocd_app_info{health_status!="Healthy"}
```

### 5.2 Out-of-Sync Applications

```promql
argocd_app_info{sync_status="OutOfSync"}
```

### 5.3 Sync Success Rate

```promql
sum(rate(argocd_app_sync_total{phase="Succeeded"}[5m])) 
/ 
sum(rate(argocd_app_sync_total[5m])) * 100
```

### 5.4 Average Sync Duration

```promql
avg(argocd_app_sync_duration_seconds)
```

---

## Step 6: Test Metrics with Real Actions

### 6.1 Create Drift and Watch Metrics

Open two browser windows:
1. Prometheus UI with query: `argocd_app_reconcile_count`
2. Terminal

Create drift:

```bash
kubectl scale deployment frontend -n microservices-demo --replicas=3
```

In Prometheus, click **Execute** repeatedly and watch the reconcile count increase!

### 6.2 Monitor Sync Operations

Query:
```promql
rate(argocd_app_sync_total[1m])
```

Then trigger a sync:

```bash
argocd app sync microservices-demo
```

Watch the sync rate spike in Prometheus!

---

## Step 7: Alert Rules

### 7.1 Create Alert Rules ConfigMap

Create `prometheus-alerts.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  alerts.yml: |
    groups:
    - name: argocd_alerts
      interval: 30s
      rules:
      
      # Alert when application is OutOfSync for too long
      - alert: ApplicationOutOfSync
        expr: argocd_app_info{sync_status="OutOfSync"} == 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Application {{ $labels.name }} is OutOfSync"
          description: "Application {{ $labels.name }} in namespace {{ $labels.namespace }} has been OutOfSync for more than 5 minutes"
      
      # Alert when application is unhealthy
      - alert: ApplicationUnhealthy
        expr: argocd_app_info{health_status!="Healthy"} == 1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Application {{ $labels.name }} is unhealthy"
          description: "Application {{ $labels.name }} health status is {{ $labels.health_status }}"
      
      # Alert on sync failures
      - alert: SyncFailureRate
        expr: rate(argocd_app_sync_total{phase="Failed"}[5m]) > 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High sync failure rate"
          description: "Application {{ $labels.name }} is experiencing sync failures"
      
      # Alert on high reconciliation rate
      - alert: HighReconciliationRate
        expr: rate(argocd_app_reconcile_count[5m]) > 1
        for: 10m
        labels:
          severity: info
        annotations:
          summary: "High reconciliation rate for {{ $labels.name }}"
          description: "Application {{ $labels.name }} is reconciling frequently, possible configuration drift"
```

### 7.2 Update Prometheus Config

Update `prometheus-config.yaml` to include alert rules:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    rule_files:
      - /etc/prometheus/alerts.yml

    scrape_configs:
    - job_name: 'argocd-metrics'
      static_configs:
      - targets:
        - argocd-metrics.argocd.svc.cluster.local:8082
        labels:
          component: application-controller

    - job_name: 'argocd-server-metrics'
      static_configs:
      - targets:
        - argocd-server-metrics.argocd.svc.cluster.local:8083
        labels:
          component: api-server

    - job_name: 'argocd-repo-server-metrics'
      static_configs:
      - targets:
        - argocd-repo-server.argocd.svc.cluster.local:8084
        labels:
          component: repo-server
```

### 7.3 Apply Alert Rules

```bash
kubectl apply -f prometheus-alerts.yaml
kubectl apply -f prometheus-config.yaml

# Restart Prometheus to load new config
kubectl rollout restart deployment prometheus -n monitoring
```

### 7.4 View Alerts in Prometheus

1. Open Prometheus UI: `http://localhost:9090`
2. Click **Alerts**
3. You should see the configured alert rules

---

## Step 8: Key Metrics Reference

### Application Metrics

| Metric | Description | Type |
|--------|-------------|------|
| `argocd_app_info` | Application information with labels | Gauge |
| `argocd_app_sync_total` | Total number of syncs | Counter |
| `argocd_app_sync_duration_seconds` | Sync duration | Histogram |
| `argocd_app_reconcile_count` | Reconciliation count | Counter |
| `argocd_app_k8s_request_total` | Kubernetes API requests | Counter |

### Controller Metrics

| Metric | Description | Type |
|--------|-------------|------|
| `argocd_app_reconcile_duration_seconds` | Reconciliation duration | Histogram |
| `argocd_kubectl_exec_pending` | Pending kubectl executions | Gauge |
| `argocd_cluster_api_resource_objects` | K8s API resource objects | Gauge |

### Git Metrics

| Metric | Description | Type |
|--------|-------------|------|
| `argocd_git_request_total` | Git operation count | Counter |
| `argocd_git_request_duration_seconds` | Git operation duration | Histogram |

---

## Step 9: Useful PromQL Queries

### Operational Queries

```promql
# Applications that need attention
count(argocd_app_info{sync_status="OutOfSync"}) + count(argocd_app_info{health_status!="Healthy"})

# Sync success rate (last hour)
sum(increase(argocd_app_sync_total{phase="Succeeded"}[1h])) / sum(increase(argocd_app_sync_total[1h])) * 100

# Most frequently reconciling apps
topk(5, rate(argocd_app_reconcile_count[5m]))

# Average time to sync
histogram_quantile(0.95, rate(argocd_app_sync_duration_seconds_bucket[5m]))

# Git operations per second
sum(rate(argocd_git_request_total[5m]))
```

### Debugging Queries

```promql
# Find applications with failed syncs
argocd_app_sync_total{phase="Failed"}

# Slow Git operations
argocd_git_request_duration_seconds > 10

# High API request rate
rate(argocd_api_server_requests_total[5m]) > 10
```

---

## Exercises

### Exercise 1: Monitor Application Deployment

1. Deploy a new application with Argo CD
2. Watch metrics in real-time
3. Observe:
   - `argocd_app_sync_total` increase
   - `argocd_app_reconcile_count` activity
   - Sync duration

### Exercise 2: Create Custom Alert

Create an alert for applications stuck in Progressing state for more than 10 minutes:

```yaml
- alert: ApplicationStuckProgressing
  expr: argocd_app_info{health_status="Progressing"} == 1
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Application stuck in Progressing"
```

### Exercise 3: Analyze Sync Patterns

Run these queries and analyze the results:
- Which applications sync most frequently?
- What's the average sync duration?
- Are there any failed syncs?

---

## Verification Checklist

- [ ] Prometheus deployed and running
- [ ] All Argo CD targets showing as UP
- [ ] Can query application metrics
- [ ] Can see sync operations in metrics
- [ ] Alert rules configured
- [ ] Understand key metrics

---

## Troubleshooting

### Problem: Targets showing as DOWN

**Solution:** Check service names and ports:
```bash
kubectl get svc -n argocd
kubectl describe svc argocd-metrics -n argocd
```

### Problem: No metrics appearing

**Solution:** Verify metrics endpoints:
```bash
kubectl port-forward -n argocd svc/argocd-metrics 8082:8082
curl http://localhost:8082/metrics
```

### Problem: Alerts not firing

**Solution:** Check alert rules:
```bash
# View Prometheus logs
kubectl logs -n monitoring -l app=prometheus

# Check rules are loaded
# In Prometheus UI: Status → Rules
```

---

## Clean Up

```bash
# Delete Prometheus
kubectl delete namespace monitoring

# Stop port forwards
pkill -f "port-forward.*9090"
pkill -f "port-forward.*8082"
```

---

## What's Next?

Proceed to:
- **[Bonus Lab 2: Argo Rollouts - Blue/Green Deployments](../bonus-lab-02-rollouts/README.md)**

---

## Key Takeaways

✅ Argo CD exposes comprehensive Prometheus metrics  
✅ Metrics cover sync status, health, and operations  
✅ Prometheus provides powerful querying with PromQL  
✅ Alert rules enable proactive monitoring  
✅ Metrics help understand GitOps patterns and issues  
✅ Essential for production Argo CD deployments  
✅ Enables data-driven decision making

---

## Additional Resources

- [Argo CD Metrics Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/metrics/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard for Argo CD](https://github.com/argoproj/argo-cd/blob/master/examples/dashboard.json)
