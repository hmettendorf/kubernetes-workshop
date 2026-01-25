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

## Step 1: Understanding App of Apps

### 1.1 The Pattern

**App of Apps** = An Argo CD Application that deploys other Applications.

**Benefits:**
- Single source of truth for all applications
- Declarative application management
- Easy environment bootstrapping
- Logical grouping of related apps
- Simplified disaster recovery

### 1.2 Use Cases

- Deploy entire microservices platform
- Separate infrastructure from applications
- Manage multiple teams' applications
- Environment-specific application sets

---

## Step 2: Prepare Directory Structure

### 2.1 Create Local Directory

```bash
mkdir -p ~/app-of-apps-demo
cd ~/app-of-apps-demo
```

### 2.2 Create Directory Structure

```bash
mkdir -p apps/infrastructure
mkdir -p apps/platform
mkdir -p apps/applications
```

Structure:
```
app-of-apps-demo/
├── root-app.yaml              # Root Application
└── apps/
    ├── infrastructure/         # Infrastructure apps
    │   ├── nginx-ingress.yaml
    │   └── cert-manager.yaml
    ├── platform/              # Platform services
    │   ├── postgresql.yaml
    │   └── redis.yaml
    └── applications/          # Business applications
        ├── frontend.yaml
        └── backend.yaml
```

---

## Step 3: Create Child Applications

### 3.1 Infrastructure: Nginx Ingress

Create `apps/infrastructure/nginx-ingress.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-ingress
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: helm-guestbook
  
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

### 3.2 Platform: Redis

Create `apps/platform/redis.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: redis
  namespace: argocd
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
    namespace: platform
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 3.3 Applications: Frontend

Create `apps/applications/frontend.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
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
    namespace: applications
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 3.4 Applications: Backend

Create `apps/applications/backend.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: helm-guestbook
  
  destination:
    server: https://kubernetes.default.svc
    namespace: applications
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## Step 4: Create Root Application

### 4.1 Create Root App Manifest

Create `root-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: apps
    directory:
      recurse: true
  
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Key Points:**
- `directory.recurse: true` - Recursively find Application manifests
- `destination.namespace: argocd` - Applications are created in argocd namespace
- Child apps deploy to their own namespaces

---

## Step 5: Deploy Using Git Repository

### 5.1 Initialize Git Repository (If Creating Your Own)

```bash
cd ~/app-of-apps-demo
git init
git add .
git commit -m "Initial app of apps structure"
```

### 5.2 Push to Remote Repository

```bash
# Add your remote
git remote add origin <your-git-repo-url>
git push -u origin main
```

### 5.3 Use Example Repository

For this lab, we'll use a pre-configured example:

```bash
# We'll use Argo CD's example apps repository
# which already has an apps directory
```

---

## Step 6: Deploy Root Application

### 6.1 Create Root Application

```bash
argocd app create root-app \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path apps \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### 6.2 Sync Root Application

```bash
argocd app sync root-app
```

### 6.3 Observe Cascade Deployment

Watch applications being created:

```bash
argocd app list
```

You should see:
- `root-app` (parent)
- Multiple child applications automatically created

---

## Step 7: Verify Deployment

### 7.1 Check All Applications

```bash
argocd app list
```

### 7.2 Check Application Tree in UI

1. Open Argo CD UI
2. Click on `root-app`
3. View the application tree showing parent-child relationships

### 7.3 Verify Namespaces

```bash
kubectl get namespaces
```

Should show: `infrastructure`, `platform`, `applications`

### 7.4 Check Resources

```bash
kubectl get all -n infrastructure
kubectl get all -n platform
kubectl get all -n applications
```

---

## Step 8: Application Dependencies

### 8.1 Add Sync Waves

Control deployment order with sync waves.

Modify `apps/infrastructure/nginx-ingress.yaml`:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

Modify `apps/platform/redis.yaml`:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"
```

Modify `apps/applications/frontend.yaml`:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "3"
```

**Deployment order:**
1. Infrastructure (wave 1)
2. Platform (wave 2)
3. Applications (wave 3)

---

## Step 9: Advanced Root App Configuration

### 9.1 Root App with Kustomize

Create `apps/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- infrastructure/nginx-ingress.yaml
- platform/redis.yaml
- applications/frontend.yaml
- applications/backend.yaml

commonLabels:
  managed-by: argocd
  environment: production
```

### 9.2 Root App with Helm

Organize apps as Helm chart:

```
root-app/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── infrastructure/
    ├── platform/
    └── applications/
```

---

## Step 10: Multi-Environment App of Apps

### 10.1 Directory Structure

```
environments/
├── base/
│   └── apps/
│       ├── app1.yaml
│       └── app2.yaml
├── dev/
│   ├── kustomization.yaml
│   └── patches/
├── staging/
│   ├── kustomization.yaml
│   └── patches/
└── production/
    ├── kustomization.yaml
    └── patches/
```

### 10.2 Dev Root App

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/apps.git
    targetRevision: HEAD
    path: environments/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 10.3 Production Root App

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/apps.git
    targetRevision: HEAD
    path: environments/production
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: false  # Manual approval for production
      selfHeal: true
```

---

## Step 11: ApplicationSets (Alternative Pattern)

ApplicationSets automate creation of multiple similar applications.

### 11.1 Create ApplicationSet

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-apps
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - app: frontend
        namespace: applications
      - app: backend
        namespace: applications
  
  template:
    metadata:
      name: '{{app}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: '{{app}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

## Exercises

### Exercise 1: Add a New Application

Add a monitoring stack application to the root app:
1. Create `apps/monitoring/prometheus.yaml`
2. Commit to Git
3. Watch it auto-deploy

### Exercise 2: Create Team-Specific Root Apps

Create separate root apps for different teams:
- `team-a-root` → deploys apps in `team-a/*`
- `team-b-root` → deploys apps in `team-b/*`

### Exercise 3: Implement Environment Promotion

Create dev, staging, and prod root apps with different sync policies.

---

## Verification Checklist

- [ ] Root application created
- [ ] Child applications auto-deployed
- [ ] Applications deployed in correct order (sync waves)
- [ ] All namespaces created
- [ ] Resources deployed successfully
- [ ] Can add new apps by committing to Git
- [ ] Understand App of Apps vs ApplicationSets

---

## Troubleshooting

### Problem: Child apps not created

**Solution:** Check root app status:
```bash
argocd app get root-app
```

Verify:
- Directory path is correct
- `recurse: true` is set
- Child app manifests are valid YAML

### Problem: Apps deploy in wrong order

**Solution:** Add sync waves:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Problem: Cannot delete root app

**Solution:** Delete with cascade:
```bash
argocd app delete root-app --cascade
```

Or delete child apps first.

---

## Clean Up

```bash
# Delete root app and all children
argocd app delete root-app --cascade

# Verify all removed
argocd app list
```

---

## What's Next?

Proceed to:
- **[Lab 6: Environment Promotion](../lab-06-environment-promotion/README.md)**

---

## Key Takeaways

✅ App of Apps enables declarative application management  
✅ Single root app can bootstrap entire environments  
✅ Sync waves control deployment order  
✅ Supports complex multi-service architectures  
✅ Essential pattern for GitOps at scale  
✅ ApplicationSets offer alternative automation
