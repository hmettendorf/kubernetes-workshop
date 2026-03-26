# Lab 5: App of Apps Pattern

## Overview

Implement the "App of Apps" pattern to manage multiple applications declaratively. This pattern is essential for bootstrapping entire environments and managing complex multi-service architectures.

**Duration:** 60 minutes

**Learning Objectives:**
- Understand the App of Apps pattern
- Create a root application that deploys child applications
- Manage application dependencies
- Bootstrap entire environments
- Organize applications hierarchically

---

## Prerequisites

- Completed Labs 1-4
- Understanding of Argo CD Applications and Projects

---

## Step 1: Get the App of Apps Example Repository

### 1.1 Option A: Use the Provided Example (Recommended)

The workshop includes a ready-to-use app-of-apps example in the `app-of-apps-example` folder.

```bash
# Navigate to the example folder
cd ~/kubernetes-workshop/handson/argocd/lab-05-app-of-apps/app-of-apps-example

# Review the structure
ls -la
```

### 1.2 Option B: Create Your Own Repository

If you want to customize or use your own repository structure, see the USAGE.md file in the example folder.

---

## Step 2: Push to Your Git Repository

### 2.1 Create a GitHub Repository

1. Go to GitHub and create a new repository named `app-of-apps-example`
2. **Don't** initialize it with README, .gitignore, or license
3. Copy the repository URL

### 2.2 Use the Setup Script (Recommended)

```bash
cd ~/kubernetes-workshop/handson/argocd/lab-05-app-of-apps/app-of-apps-example

# Run the setup script
./setup.sh
```

The script will:
- Initialize Git if needed
- Ask for your repository URL
- Update `root-app.yaml` with your repository URL
- Commit all files
- Prepare for push

### 2.3 Push to GitHub

```bash
git push -u origin main
```

### 2.4 Manual Setup (Alternative)

If you prefer manual setup:

```bash
cd ~/kubernetes-workshop/handson/argocd/lab-05-app-of-apps/app-of-apps-example

# Initialize Git
git init
git add .
git commit -m "Initial app of apps structure"
git branch -M main

# Add your remote
git remote add origin https://github.com/YOUR-USERNAME/app-of-apps-example.git

# Update root-app.yaml - replace YOUR-USERNAME with your GitHub username
# Edit the repoURL line in root-app.yaml

# Push
git push -u origin main
```

---

## Step 3: Review the Repository Structure

Your repository now contains:

```
app-of-apps-example/
├── README.md                   # Documentation
├── USAGE.md                    # Quick start guide
├── setup.sh                    # Setup helper script
├── root-app.yaml              # Root Application (deploy this to ArgoCD)
└── apps/                      # Child applications
    ├── infrastructure/        # Infrastructure layer (sync-wave: 1)
    │   ├── nginx-ingress.yaml
    │   └── cert-manager.yaml
    ├── platform/             # Platform services layer (sync-wave: 2)
    │   ├── redis.yaml
    │   └── postgresql.yaml
    └── applications/         # Application layer (sync-wave: 3)
        ├── frontend.yaml
        └── backend.yaml
```

**Key Features:**
- **Sync Waves**: Applications deploy in order (1 → 2 → 3)
- **Auto-sync**: All applications have automated sync enabled
- **Self-Heal**: Changes are automatically reverted
- **Prune**: Deleted resources are removed from cluster

---

## Step 4: Understanding App of Apps

### 4.1 The Pattern

**App of Apps** = An Argo CD Application that deploys other Applications.

**Benefits:**
- Single source of truth for all applications
- Declarative application management
- Easy environment bootstrapping
- Logical grouping of related apps
- Simplified disaster recovery

### 4.2 Use Cases

- Deploy entire microservices platform
- Separate infrastructure from applications
- Manage multiple teams' applications
- Environment-specific application sets

---

## Step 5: Deploy the Root Application

### 5.1 Verify Your Repository

Make sure your repository is accessible:

```bash
# Test clone
git clone https://github.com/YOUR-USERNAME/app-of-apps-example.git /tmp/test-clone
ls /tmp/test-clone/apps/
rm -rf /tmp/test-clone
```

### 5.2 Deploy via kubectl

```bash
cd ~/kubernetes-workshop/handson/argocd/lab-05-app-of-apps/app-of-apps-example

# Make sure root-app.yaml has your correct repository URL
cat root-app.yaml | grep repoURL

# Deploy the root application
kubectl apply -f root-app.yaml
```

### 5.3 Deploy via ArgoCD UI (Alternative)

1. Open ArgoCD UI: `https://localhost:8080`
2. Click **+ NEW APP**
3. Fill in the application details:
   - **Application Name**: `root-app`
   - **Project**: `default`
   - **Sync Policy**: Check **Auto-Create Namespace**

4. In the **SOURCE** section:
   - **Repository URL**: `https://github.com/YOUR-USERNAME/app-of-apps-example.git`
   - **Revision**: `main`
   - **Path**: `apps`

5. In the **DESTINATION** section:
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `argocd`

6. Scroll down to **DIRECTORY** section:
   - Check ☑ **Recurse**

7. Click **CREATE** at the top

8. Click **SYNC** → **SYNCHRONIZE**

---

## Step 6: Watch the Cascade Deployment

### 6.1 Observe in ArgoCD UI

1. The **root-app** will appear first
2. After syncing, 6 child applications will be created automatically:
   - **Wave 1** (Infrastructure): nginx-ingress, cert-manager
   - **Wave 2** (Platform): redis, postgresql  
   - **Wave 3** (Applications): frontend, backend

3. Click on **root-app** to see the application tree
4. Watch applications deploy in waves

### 6.2 Monitor via kubectl

```bash
# Watch applications being created
watch kubectl get applications -n argocd

# In another terminal, check namespaces
kubectl get namespaces | grep -E "infrastructure|platform|applications"

# Check pods in each namespace
kubectl get pods -n infrastructure
kubectl get pods -n platform
kubectl get pods -n applications
```

### 6.3 Verify Deployment Order

Check the sync-wave annotations ensured correct order:

```bash
# Check application creation timestamps
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,CREATED:.metadata.creationTimestamp

# Infrastructure apps should appear first, then platform, then applications
```

---

## Step 7: Explore the Application Hierarchy

### 7.1 View in UI

1. Click on the **root-app** in ArgoCD UI
2. You'll see a tree structure showing:
   - The root app at the top
   - All 6 child Application resources
   - Each child app's resources (deployments, services, etc.)

3. Click on individual child applications to explore them

### 7.2 Understand the Relationship

The root-app watches the `apps/` directory:
- When you add a new YAML file → New application created
- When you modify a file → Application updated
- When you delete a file → Application removed (if prune enabled)

---

## Step 8: Test Dynamic Application Creation

### 8.1 Add a New Application

Let's add a monitoring application:

```bash
cd ~/kubernetes-workshop/handson/argocd/lab-05-app-of-apps/app-of-apps-example

# Create new application file
cat > apps/infrastructure/monitoring.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  
  destination:
    server: https://kubernetes.default.svc
    namespace: infrastructure
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# Commit and push
git add apps/infrastructure/monitoring.yaml
git commit -m "Add monitoring to infrastructure"
git push
```

### 8.2 Watch ArgoCD Auto-Detect

In the ArgoCD UI:
1. Wait 3 minutes (default refresh interval) or click **REFRESH** on root-app
2. A new **monitoring** application will appear automatically!
3. It will sync and deploy to the infrastructure namespace

### 8.3 Remove an Application

```bash
# Delete the monitoring application
git rm apps/infrastructure/monitoring.yaml
git commit -m "Remove monitoring"
git push

# Watch it get deleted from ArgoCD (if prune is enabled)
```

---

## Step 9: Multi-Environment Pattern

### 9.1 Understanding Environment Separation

You can extend the app-of-apps pattern for multiple environments:

```
environments/
├── base/apps/           # Base application definitions
├── dev/
│   ├── root-app.yaml   # Points to base + dev overlays
│   └── overlays/
├── staging/
│   ├── root-app.yaml
│   └── overlays/
└── prod/
    ├── root-app.yaml
    └── overlays/
```

### 9.2 Example: Dev vs Prod Root Apps

**Dev Root App** (auto-sync enabled):
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

**Prod Root App** (manual sync required):
```yaml
syncPolicy:
  automated:
    prune: false
    selfHeal: false
  # Requires manual approval
```

---

## Step 10: Exercises

### Exercise 1: Add a New Application

Add a database application to the platform layer:

1. Create `apps/platform/database.yaml` in your repository
2. Set sync-wave to "2" (platform layer)
3. Commit and push
4. Watch it auto-deploy!

### Exercise 2: Test Deletion

1. Delete one of the child application files from Git
2. Commit and push
3. Watch ArgoCD remove it (because prune is enabled)
4. Re-add it to restore

### Exercise 3: Manual Sync Testing

1. Edit one child application to remove auto-sync
2. Make a change to that application's source
3. Observe it stays OutOfSync
4. Manually sync it via UI

### Exercise 4: Create Team-Specific Root Apps

Design (don't implement) separate root apps for different teams:
- `team-platform-root` → deploys `apps/team-platform/*`
- `team-apps-root` → deploys `apps/team-apps/*`

---

## Verification Checklist

- [ ] Repository pushed to GitHub successfully
- [ ] Root application deployed
- [ ] 6 child applications auto-created
- [ ] Applications deployed in correct wave order
- [ ] All namespaces created (infrastructure, platform, applications)
- [ ] Resources running in each namespace
- [ ] Can add new application by committing to Git
- [ ] Understand cascade deletion

---

## Troubleshooting

### Problem: Child apps not created

**Solution via UI:**
1. Click on the **root-app**
2. Check the **EVENTS** tab for errors
3. Verify **DIRECTORY** section shows `Recurse: true`
4. Click **APP DETAILS** and check the source path is `apps`

**Via kubectl:**
```bash
kubectl describe application root-app -n argocd
```

Verify:
- Repository URL is correct and accessible
- `directory.recurse: true` is set
- Path is set to `apps`

### Problem: Apps deploy in wrong order

**Solution:** Check sync-wave annotations:
```bash
# Check all applications' sync-waves
cd ~/kubernetes-workshop/handson/argocd/lab-05-app-of-apps/app-of-apps-example
grep -r "sync-wave" apps/
```

Infrastructure should be wave 1, platform wave 2, applications wave 3.

### Problem: Cannot delete root app

**Solution via UI:**
1. Click on `root-app`
2. Click the three dots ⋮  
3. Select **Delete**
4. Check ☑ **Cascade**
5. Confirm deletion

**Via kubectl:**
```bash
kubectl delete application root-app -n argocd --cascade=foreground
```

### Problem: Wrong repository URL

**Solution:**
1. Edit `root-app.yaml` in your local copy
2. Update the `repoURL` field
3. Apply changes:
```bash
kubectl apply -f root-app.yaml
```

Or update via UI:
1. Click on `root-app`
2. Click **APP DETAILS**
3. Click **EDIT**
4. Update **Repository URL**
5. Click **SAVE**

---

## Clean Up

### Via UI (Recommended)

1. Go to the Applications view
2. Click on `root-app`
3. Click the three dots ⋮
4. Select **Delete**
5. Check ☑ **Cascade** (this deletes all 6 child applications too!)
6. Confirm deletion

### Via kubectl

```bash
# Delete root app and all children
kubectl delete application root-app -n argocd --cascade=foreground

# Verify all removed
kubectl get applications -n argocd
kubectl get namespaces | grep -E "infrastructure|platform|applications"
```

---

## What's Next?

Congratulations! You've completed all main ArgoCD labs.

Consider exploring:
- **[Bonus Lab 1: Prometheus Metrics](../bonus-lab-01-prometheus/README.md)** - Monitor ArgoCD with metrics
- **[Bonus Lab 2: Argo Rollouts](../bonus-lab-02-rollouts/README.md)** - Progressive delivery strategies

---

## Key Takeaways

✅ App of Apps enables declarative application management at scale  
✅ Single root app can bootstrap entire environments  
✅ Sync waves control deployment order and dependencies  
✅ Perfect for separating infrastructure, platform, and applications  
✅ Adding new apps is as simple as committing a YAML file  
✅ Cascade deletion makes cleanup easy  
✅ The pattern is essential for GitOps at enterprise scale  
✅ Can be extended to multi-environment and multi-cluster scenarios

---

## Additional Resources

- [App of Apps Pattern Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Sync Waves and Hooks](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [ApplicationSet vs App of Apps](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Example Repository](https://github.com/argoproj/argocd-example-apps)
