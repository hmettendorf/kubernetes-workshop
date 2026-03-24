# Lab 3: Drift Detection & Self-Healing

## Overview

Explore Argo CD's drift detection capabilities and automated reconciliation using the microservices demo application. Learn how Argo CD keeps your cluster in sync with Git.

**Duration:** 45 minutes

**Learning Objectives:**
- Understand drift and why it matters
- Manually create drift by changing resources
- Observe Argo CD's drift detection
- Enable and test self-healing
- Configure sync policies for different scenarios

---

## Prerequisites

- Completed Lab 1 & 2
- Microservices demo application deployed (or create it again)

---

## Step 1: Ensure Application is Deployed

### 1.1 Check Application Status

```bash
argocd app list
```

If microservices-demo isn't deployed, create it:

```bash
argocd app create microservices-demo \
  --repo https://github.com/GoogleCloudPlatform/microservices-demo.git \
  --path release \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace microservices-demo \
  --sync-option CreateNamespace=true

argocd app sync microservices-demo
```

### 1.2 Verify Healthy State

```bash
argocd app get microservices-demo
```

Should show:
- **STATUS: Synced**
- **HEALTH: Healthy**

Wait for all pods to be running:

```bash
kubectl get pods -n microservices-demo
```

---

## Step 2: Create Drift Manually (Scaling)

### 2.1 Check Current State

View current replicas for the frontend service:

```bash
kubectl get deployment frontend -n microservices-demo
```

Expected: `REPLICAS: 1`

### 2.2 Manually Scale Deployment

Create drift by scaling directly with kubectl:

```bash
kubectl scale deployment frontend --replicas=3 -n microservices-demo
```

### 2.3 Verify the Change

```bash
kubectl get deployment frontend -n microservices-demo
kubectl get pods -n microservices-demo -l app=frontend
```

Now shows: `REPLICAS: 3` and you'll see 3 frontend pods running.

---

## Step 3: Observe Drift Detection

### 3.1 Check Application Status (CLI)

```bash
argocd app get microservices-demo
```

After a few seconds (Argo CD polls every 3 minutes by default), status will show:
- **STATUS: OutOfSync**
- Diff showing replica count changed

If it hasn't detected yet, force a refresh:

```bash
argocd app get microservices-demo --refresh
```

### 3.2 View Detailed Diff

```bash
argocd app diff microservices-demo
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
2. Click on **microservices-demo** application
3. Notice the **OutOfSync** badge
4. Click **APP DIFF** button to see differences
5. Click on the **frontend** deployment to see specific changes

The UI highlights:
- Resources that are out of sync (yellow indicator)
- Specific field differences
- Color coding (red = removed, green = added)

---

## Step 4: Manual Reconciliation

### 4.1 Sync to Fix Drift

Sync the application to restore Git state:

```bash
argocd app sync microservices-demo
```

### 4.2 Verify Reconciliation

```bash
kubectl get deployment frontend -n microservices-demo
```

Replicas should be back to: `1`

```bash
argocd app get microservices-demo
```

Status should show: **Synced** and **Healthy**

---

## Step 5: Enable Self-Healing

Self-healing automatically reverts manual changes.

### 5.1 Current Sync Policy

View current policy:

```bash
argocd app get microservices-demo | grep -A 3 "Sync Policy"
```

Shows: Manual sync (no automated policy)

### 5.2 Enable Automated Sync with Self-Heal

Update the application to enable self-healing:

```bash
argocd app set microservices-demo \
  --sync-policy automated \
  --self-heal
```

### 5.3 Verify Configuration

```bash
argocd app get microservices-demo
```

Should show:
```
Sync Policy:     Automated
  Self Heal:     true
```

---

## Step 6: Test Self-Healing

### 6.1 Create Drift Again

Scale a different service this time:

```bash
kubectl scale deployment recommendationservice --replicas=3 -n microservices-demo
```

### 6.2 Watch Auto-Reconciliation

Watch the deployment:

```bash
kubectl get deployment recommendationservice -n microservices-demo --watch
```

Within seconds (usually 5-10s), you'll see replicas automatically change back to `1`.

Press `Ctrl+C` to stop watching.

### 6.3 Check in UI

1. Open the Argo CD UI
2. Watch the **microservices-demo** application
3. You might briefly see it go OutOfSync, then immediately Synced again
4. Click on Activity tab to see the self-heal event

### 6.4 Check Application Events

```bash
argocd app get microservices-demo
```

Look for recent sync events showing self-healing.

---

## Step 7: Test Configuration Changes

### 7.1 Modify Environment Variable

Let's modify an environment variable on one of the services:

```bash
kubectl set env deployment/frontend -n microservices-demo TEST_VAR=changed
```

### 7.2 Observe Self-Healing

Watch the deployment:

```bash
kubectl get deployment frontend -n microservices-demo -o yaml | grep -A 5 "env:"
```

Within seconds, the change will be reverted (the TEST_VAR removed).

Check Argo CD:

```bash
argocd app get microservices-demo
```

Should show Synced status again.

---

## Step 8: Test Configuration Changes

### 8.1 Modify Environment Variable

Let's modify an environment variable on one of the services:

```bash
kubectl set env deployment/frontend -n microservices-demo TEST_VAR=changed
```

### 8.2 Observe Self-Healing

Watch the deployment:

```bash
kubectl get deployment frontend -n microservices-demo -o yaml | grep -A 5 "env:"
```

Within seconds, the change will be reverted (the TEST_VAR removed).

Check Argo CD:

```bash
argocd app get microservices-demo
```

Should show Synced status again.

### 8.3 Service Modifications (Advanced)

If you patched the frontend-external service NodePort earlier (in Lab 2, Step 5), that's also drift! Let's check:

```bash
# Check current service NodePort
kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.spec.ports[0].nodePort}'

# Refresh Argo CD to detect drift
argocd app get microservices-demo --refresh
```

**Important:** Service modifications are detected by Argo CD, but since we manually patched it (outside of Git), self-healing would revert it to a random NodePort. This demonstrates why GitOps requires all changes to be in Git!

**To persist the NodePort change in a GitOps way, you would need to:**
1. Fork the microservices-demo repository
2. Modify the Helm chart or use Kustomize patches
3. Point your Application to your forked repo
4. Commit the NodePort configuration to Git

For this workshop, we accept the random NodePort or use port-forwarding to avoid this complexity.

---

## Step 9: Configure Prune Policy

Prune automatically deletes resources removed from Git.

### 9.1 Enable Prune

```bash
argocd app set microservices-demo --auto-prune
```

### 9.2 Verify Configuration

```bash
argocd app get microservices-demo
```

Should show:
```
Sync Policy:     Automated
  Prune:         true
  Self Heal:     true
```

### 9.3 Understanding Prune

**What happens:** If you remove a resource from Git, Argo CD will delete it from the cluster.

**Example scenario:**
1. Fork the microservices-demo repository
2. Remove a service definition from the manifests
3. Commit and push
4. Argo CD will delete that Service from the cluster automatically

**Note:** For this workshop, we won't modify the upstream repo, but it's important to understand how prune works.

---

## Step 10: Declarative Sync Policy

Let's update the application using a manifest instead of CLI commands.

### 10.1 Create Updated Application Manifest

Create `microservices-demo-selfheal.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-demo
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/GoogleCloudPlatform/microservices-demo.git
    targetRevision: HEAD
    path: release
  
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices-demo
  
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

### 10.2 Apply the Manifest

```bash
kubectl apply -f microservices-demo-selfheal.yaml
```

This is the GitOps way - everything defined declaratively!

---

## Step 11: Ignore Differences

Sometimes you want to ignore certain fields (e.g., fields managed by other controllers).

### 11.1 Understanding Ignore Rules

Common use cases:
- Ignore replica counts when using HPA (HorizontalPodAutoscaler)
- Ignore status fields
- Ignore annotations added by other tools

### 11.2 Configure Ignore Rules

Create `microservices-demo-ignore.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-demo
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/GoogleCloudPlatform/microservices-demo.git
    targetRevision: HEAD
    path: release
  
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices-demo
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
  
  # Ignore replica count on loadgenerator (example)
  ignoreDifferences:
  - group: apps
    kind: Deployment
    name: loadgenerator
    jsonPointers:
    - /spec/replicas
```

### 11.3 Test Ignore Rules

```bash
kubectl apply -f microservices-demo-ignore.yaml

# Scale loadgenerator
kubectl scale deployment loadgenerator --replicas=3 -n microservices-demo

# Check status
argocd app get microservices-demo
```

The app should remain **Synced** because we're ignoring replica changes on loadgenerator!

---

## Exercises

### Exercise 1: Test Self-Heal with Multiple Services

Scale multiple services simultaneously and watch them all self-heal:

```bash
kubectl scale deployment frontend --replicas=2 -n microservices-demo
kubectl scale deployment cartservice --replicas=2 -n microservices-demo
kubectl scale deployment productcatalogservice --replicas=2 -n microservices-demo

# Watch them all revert
watch kubectl get deployments -n microservices-demo
```

### Exercise 2: Disable Self-Heal Temporarily

```bash
argocd app set microservices-demo --self-heal=false
kubectl scale deployment frontend --replicas=3 -n microservices-demo
# Observe: Drift detected but NOT auto-corrected

# Re-enable
argocd app set microservices-demo --self-heal=true
```

### Exercise 3: Explore Sync Options

Add different sync options:

```yaml
syncPolicy:
  syncOptions:
  - CreateNamespace=true
  - PrunePropagationPolicy=foreground
  - PruneLast=true
  - ApplyOutOfSyncOnly=true
```

Apply and observe behavior.

---

## Verification Checklist

- [ ] Can create drift manually
- [ ] Argo CD detects drift
- [ ] Can view diff in UI and CLI
- [ ] Self-healing automatically corrects drift
- [ ] Understand prune behavior
- [ ] Can configure ignore rules
- [ ] Understand sync retry logic

---

## Troubleshooting

### Problem: Self-heal not working

**Solution:** Check sync policy is enabled:
```bash
argocd app get microservices-demo | grep "Self Heal"
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
argocd app get microservices-demo | grep Prune
```

Should show: `Prune: true`

### Problem: Application shows Degraded health

**Solution:** Check individual pod status:
```bash
kubectl get pods -n microservices-demo
kubectl describe pod <failing-pod> -n microservices-demo
```

May need to increase Rancher Desktop resources.

---

## Clean Up

Keep the microservices-demo app for the next lab, or delete:

```bash
argocd app delete microservices-demo
```

---

## What's Next?

Proceed to:
- **[Lab 4: AppProjects & Multi-Tenancy](../lab-04-appprojects/README.md)**

---

## Key Takeaways

✅ Drift detection ensures cluster matches Git state  
✅ Self-healing automatically reverts manual changes within seconds  
✅ Prune removes resources deleted from Git  
✅ Sync options provide fine-grained control  
✅ Ignore rules handle special cases (HPA, external controllers)  
✅ Sync retry provides resilience for transient failures  
✅ Declarative sync policies enable complete GitOps automation  
✅ Multi-service applications demonstrate the power of GitOps at scale
