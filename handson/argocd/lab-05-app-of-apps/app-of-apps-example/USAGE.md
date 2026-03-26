# Quick Start Guide

## Setup (5 minutes)

### 1. Create a new GitHub repository

```bash
# Go to GitHub and create a new repository named 'app-of-apps-example'
# Don't initialize it with README, .gitignore, or license
```

### 2. Push this folder to GitHub

```bash
cd app-of-apps-example

# Option A: Use the setup script (recommended)
./setup.sh

# Option B: Manual setup
git init
git add .
git commit -m "Initial app of apps structure"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/app-of-apps-example.git

# Update root-app.yaml with your repository URL
# Replace: https://github.com/YOUR-USERNAME/app-of-apps-example.git

git push -u origin main
```

### 3. Deploy the root application

**Option A: Via kubectl**
```bash
kubectl apply -f root-app.yaml
```

**Option B: Via ArgoCD UI**
1. Open ArgoCD UI: `https://localhost:8080`
2. Click **+ NEW APP**
3. Fill in:
   - **Application Name**: `root-app`
   - **Project**: `default`
   - **Repository URL**: `https://github.com/YOUR-USERNAME/app-of-apps-example.git`
   - **Revision**: `main`
   - **Path**: `apps`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `argocd`
4. Scroll down to **Directory**
   - Check ☑ **Recurse**
5. Click **CREATE**
6. Click **SYNC** → **SYNCHRONIZE**

### 4. Watch the cascade deployment

In the ArgoCD UI:
- You'll see the `root-app` appear first
- Then 6 child applications will be created automatically:
  - Wave 1 (Infrastructure): nginx-ingress, cert-manager
  - Wave 2 (Platform): redis, postgresql
  - Wave 3 (Applications): frontend, backend

## What You'll See

### In ArgoCD UI
- **root-app**: The parent application
- **6 child applications**: Automatically created by the root app
- **3 namespaces**: infrastructure, platform, applications
- **Sync waves**: Apps deploy in order (1 → 2 → 3)

### In Kubernetes
```bash
# Check all applications
kubectl get applications -n argocd

# Check created namespaces
kubectl get namespaces | grep -E "infrastructure|platform|applications"

# Check pods in each namespace
kubectl get pods -n infrastructure
kubectl get pods -n platform
kubectl get pods -n applications
```

## Customization Examples

### Add a new infrastructure component

Create `apps/infrastructure/monitoring.yaml`:
```yaml
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
```

Commit and push:
```bash
git add apps/infrastructure/monitoring.yaml
git commit -m "Add monitoring to infrastructure"
git push
```

ArgoCD will automatically detect and deploy it!

### Change sync policy

To require manual approval for production apps:

Edit `apps/applications/backend.yaml`:
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: false  # Disable self-heal
  syncOptions:
  - CreateNamespace=true
```

Or remove `automated` entirely for fully manual sync.

## Cleanup

### Delete everything via UI
1. Go to Applications
2. Click on `root-app`
3. Click the three dots ⋮
4. Select **Delete**
5. Check ☑ **Cascade**
6. Confirm

This will delete the root app and all 6 child applications!

### Delete via kubectl
```bash
kubectl delete application root-app -n argocd --cascade=foreground
```

## Troubleshooting

### Applications not appearing
- Check the root-app is synced
- Verify `directory.recurse: true` is set
- Check ArgoCD can access your Git repository

### Wrong repository URL
Edit `root-app.yaml` and update the `repoURL`, then:
```bash
kubectl apply -f root-app.yaml
```

### Applications in wrong order
Check the `sync-wave` annotations:
- Wave 1: Infrastructure
- Wave 2: Platform  
- Wave 3: Applications

Lower numbers deploy first.
