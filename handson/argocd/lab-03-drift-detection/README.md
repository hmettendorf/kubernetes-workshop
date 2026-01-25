# Lab 3: Drift Detection & Self-Healing

## Overview

Explore Argo CD's drift detection capabilities and automated reconciliation. Learn how Argo CD keeps your cluster in sync with Git.

**Duration:** 30 minutes

**Learning Objectives:**
- Understand drift and why it matters
- Manually create drift by changing resources
- Observe Argo CD's drift detection
- Enable and test self-healing
- Configure sync policies

---

## Prerequisites

- Completed Lab 1 & 2
- Guestbook application deployed (or create it again)

---

## Step 1: Ensure Application is Deployed

### 1.1 Check Application Status

```bash
argocd app list
```

If guestbook isn't deployed, create it:

```bash
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

argocd app sync guestbook
```

### 1.2 Verify Healthy State

```bash
argocd app get guestbook
```

Should show:
- **STATUS: Synced**
- **HEALTH: Healthy**

---

## Step 2: Create Drift Manually

### 2.1 Check Current State

View current replicas:

```bash
kubectl get deployment guestbook-ui -n default
```

Expected: `REPLICAS: 1`

### 2.2 Manually Scale Deployment

Create drift by scaling directly with kubectl:

```bash
kubectl scale deployment guestbook-ui --replicas=3 -n default
```

### 2.3 Verify the Change

```bash
kubectl get deployment guestbook-ui -n default
```

Now shows: `REPLICAS: 3`

---

## Step 3: Observe Drift Detection

### 3.1 Check Application Status (CLI)

```bash
argocd app get guestbook
```

After a few seconds (Argo CD polls every 3 minutes by default), status will show:
- **STATUS: OutOfSync**
- Diff showing replica count changed

If it hasn't detected yet, force a refresh:

```bash
argocd app get guestbook --refresh
```

### 3.2 View Detailed Diff

```bash
argocd app diff guestbook
```

This shows the exact differences between Git and cluster:

```diff
- spec:
-   replicas: 1
+ spec:
+   replicas: 3
```

### 3.3 Observe in UI

1. Open Argo CD UI
2. Click on **guestbook** application
3. Notice the **OutOfSync** badge
4. Click **APP DIFF** button to see differences

The UI highlights:
- Resources that are out of sync
- Specific field differences
- Color coding (red = removed, green = added)

---

## Step 4: Manual Reconciliation

### 4.1 Sync to Fix Drift

Sync the application to restore Git state:

```bash
argocd app sync guestbook
```

### 4.2 Verify Reconciliation

```bash
kubectl get deployment guestbook-ui -n default
```

Replicas should be back to: `1`

```bash
argocd app get guestbook
```

Status should show: **Synced** and **Healthy**

---

## Step 5: Enable Self-Healing

Self-healing automatically reverts manual changes.

### 5.1 Current Sync Policy

View current policy:

```bash
argocd app get guestbook | grep -A 3 "Sync Policy"
```

Shows: `Sync Policy: <none>` (manual sync)

### 5.2 Enable Automated Sync with Self-Heal

Update the application to enable self-healing:

```bash
argocd app set guestbook \
  --sync-policy automated \
  --self-heal
```

### 5.3 Verify Configuration

```bash
argocd app get guestbook
```

Should show:
```
Sync Policy:     Automated
  Self Heal:     true
```

---

## Step 6: Test Self-Healing

### 6.1 Create Drift Again

```bash
kubectl scale deployment guestbook-ui --replicas=5 -n default
```

### 6.2 Watch Auto-Reconciliation

Watch the deployment:

```bash
kubectl get deployment guestbook-ui -n default --watch
```

Within seconds (usually 5-10s), you'll see replicas automatically change back to `1`.

Press `Ctrl+C` to stop watching.

### 6.3 Check Application Logs

```bash
argocd app logs guestbook --kind Deployment --name guestbook-ui
```

Shows reconciliation events.

---

## Step 7: Test Label Changes

### 7.1 Add a Label

Add a custom label to the deployment:

```bash
kubectl label deployment guestbook-ui -n default custom-label=test
```

### 7.2 Observe Self-Healing

Check the label:

```bash
kubectl get deployment guestbook-ui -n default --show-labels
```

The custom label will be removed automatically by self-heal.

Verify:
```bash
kubectl get deployment guestbook-ui -n default --show-labels
```

---

## Step 8: Test Resource Deletion

### 8.1 Delete a Pod

```bash
kubectl delete pod -l app=guestbook-ui -n default
```

### 8.2 Watch Recreation

The deployment controller will recreate it immediately:

```bash
kubectl get pods -l app=guestbook-ui -n default --watch
```

---

## Step 9: Configure Prune Policy

Prune automatically deletes resources removed from Git.

### 9.1 Enable Prune

```bash
argocd app set guestbook --auto-prune
```

### 9.2 Verify Configuration

```bash
argocd app get guestbook
```

Should show:
```
Sync Policy:     Automated
  Prune:         true
  Self Heal:     true
```

### 9.3 Test Prune (Simulation)

**What happens:** If you remove a resource from Git, Argo CD will delete it from the cluster.

**Example scenario:**
1. Fork the example repo
2. Remove `service.yaml` from Git
3. Commit and push
4. Argo CD will delete the Service from the cluster

---

## Step 10: Sync Windows

Control when syncs can happen (e.g., maintenance windows).

### 10.1 View Project Sync Windows

```bash
argocd proj get default
```

Currently, no sync windows are configured.

### 10.2 Create Application Manifest with Sync Window

Create `guestbook-sync-window.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook-scheduled
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

---

## Step 11: Sync Options

Explore additional sync options.

### 11.1 Common Sync Options

```yaml
syncPolicy:
  syncOptions:
  - CreateNamespace=true       # Auto-create namespace if missing
  - PrunePropagationPolicy=foreground  # How to delete resources
  - PruneLast=true             # Prune resources after sync
  - Validate=false             # Skip kubectl validation
  - ApplyOutOfSyncOnly=true    # Only sync out-of-sync resources
```

### 11.2 Apply Sync Options

```bash
argocd app set guestbook --sync-option CreateNamespace=true
```

---

## Step 12: Ignore Differences

Sometimes you want to ignore certain fields (e.g., HPA-managed replicas).

### 12.1 Configure Ignore Rules

Edit application manifest to add:

```yaml
spec:
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

This tells Argo CD to ignore replica count differences.

### 12.2 Apply Configuration

```bash
kubectl apply -f guestbook-app.yaml
```

Now manual scaling won't trigger OutOfSync status!

---

## Exercises

### Exercise 1: Test Self-Heal with ConfigMap

1. Create a ConfigMap in the namespace
2. Watch Argo CD remove it (if not in Git)

```bash
kubectl create configmap test --from-literal=key=value -n default
kubectl get configmap test -n default --watch
```

### Exercise 2: Disable Self-Heal Temporarily

```bash
argocd app set guestbook --self-heal=false
kubectl scale deployment guestbook-ui --replicas=3 -n default
# Observe: Drift detected but NOT auto-corrected
```

### Exercise 3: Configure Sync Retry

Add retry logic for failed syncs:

```yaml
syncPolicy:
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

---

## Verification Checklist

- [ ] Can create drift manually
- [ ] Argo CD detects drift
- [ ] Can view diff in UI and CLI
- [ ] Self-healing automatically corrects drift
- [ ] Prune deletes resources removed from Git
- [ ] Understand ignore rules

---

## Troubleshooting

### Problem: Self-heal not working

**Solution:** Check sync policy is enabled:
```bash
argocd app get guestbook | grep "Self Heal"
```

Should show: `Self Heal: true`

### Problem: Too frequent reconciliation

**Solution:** Argo CD checks every 3 minutes by default. To change:

Edit `argocd-cm` ConfigMap:
```bash
kubectl edit configmap argocd-cm -n argocd
```

Add:
```yaml
data:
  timeout.reconciliation: 5m  # Check every 5 minutes
```

### Problem: Resources not being pruned

**Solution:** Ensure prune is enabled:
```bash
argocd app get guestbook | grep Prune
```

---

## Clean Up

Keep the guestbook app for the next lab, or delete:

```bash
argocd app delete guestbook
```

---

## What's Next?

Proceed to:
- **[Lab 4: AppProjects & Multi-Tenancy](../lab-04-appprojects/README.md)**

---

## Key Takeaways

✅ Drift detection ensures cluster matches Git state  
✅ Self-healing automatically reverts manual changes  
✅ Prune removes resources deleted from Git  
✅ Sync options provide fine-grained control  
✅ Ignore rules handle special cases (HPA, etc.)  
✅ GitOps ensures declarative, auditable deployments
