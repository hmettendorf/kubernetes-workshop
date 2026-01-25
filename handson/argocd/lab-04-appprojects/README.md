# Lab 4: AppProjects & Multi-Tenancy

## Overview

Learn how to use AppProjects to implement multi-tenancy, isolate teams, and enforce policies in Argo CD.

**Duration:** 45 minutes

**Learning Objectives:**
- Create and configure AppProjects
- Restrict source repositories
- Limit destination clusters and namespaces
- Configure resource whitelists/blacklists
- Implement team-based isolation
- Set up RBAC policies

---

## Prerequisites

- Completed Labs 1-3
- Multiple namespaces for testing

---

## Step 1: Understanding AppProjects

### 1.1 View Default Project

Every Argo CD installation has a `default` project:

```bash
argocd proj get default
```

Shows:
- No restrictions on source repos
- Can deploy to any cluster/namespace
- All resources allowed

### 1.2 List All Projects

```bash
argocd proj list
```

Currently shows only: `default`

---

## Step 2: Create Team Namespaces

### 2.1 Create Namespaces for Two Teams

```bash
kubectl create namespace team-a
kubectl create namespace team-b
kubectl create namespace shared
```

### 2.2 Verify Namespaces

```bash
kubectl get namespaces | grep team
```

---

## Step 3: Create Team A Project

### 3.1 Create Project via CLI

```bash
argocd proj create team-a \
  --description "Project for Team A" \
  --dest https://kubernetes.default.svc,team-a \
  --dest https://kubernetes.default.svc,shared \
  --src https://github.com/argoproj/argocd-example-apps.git
```

**Parameters:**
- `--dest` - Allowed destination (cluster,namespace)
- `--src` - Allowed source repository

### 3.2 Verify Project Creation

```bash
argocd proj get team-a
```

Shows project configuration with restrictions.

---

## Step 4: Create Project Declaratively

### 4.1 Create Team B Project Manifest

Create `team-b-project.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-b
  namespace: argocd
spec:
  description: Project for Team B
  
  # Source repositories
  sourceRepos:
  - https://github.com/argoproj/argocd-example-apps.git
  - https://github.com/your-org/*  # Wildcard allowed
  
  # Destination clusters and namespaces
  destinations:
  - namespace: team-b
    server: https://kubernetes.default.svc
  - namespace: shared
    server: https://kubernetes.default.svc
  
  # Cluster resource whitelist
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  
  # Namespace resource whitelist
  namespaceResourceWhitelist:
  - group: 'apps'
    kind: Deployment
  - group: 'apps'
    kind: StatefulSet
  - group: ''
    kind: Service
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  
  # Namespace resource blacklist (take precedence over whitelist)
  namespaceResourceBlacklist:
  - group: ''
    kind: ResourceQuota
  - group: ''
    kind: LimitRange
```

### 4.2 Apply Project

```bash
kubectl apply -f team-b-project.yaml
```

### 4.3 Verify

```bash
argocd proj get team-b
```

---

## Step 5: Deploy Applications to Projects

### 5.1 Create Application for Team A

```bash
argocd app create team-a-guestbook \
  --project team-a \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace team-a
```

### 5.2 Sync Application

```bash
argocd app sync team-a-guestbook
```

### 5.3 Create Application for Team B

```bash
argocd app create team-b-guestbook \
  --project team-b \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path helm-guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace team-b
```

```bash
argocd app sync team-b-guestbook
```

---

## Step 6: Test Project Restrictions

### 6.1 Try to Deploy to Wrong Namespace

Attempt to create an app for team-a in team-b namespace:

```bash
argocd app create team-a-wrong \
  --project team-a \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace team-b
```

**Expected:** Error - namespace not permitted!

### 6.2 Try Unauthorized Repository

```bash
argocd app create team-a-unauthorized \
  --project team-a \
  --repo https://github.com/unauthorized/repo.git \
  --path app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace team-a
```

**Expected:** Error - repository not in allowed list!

---

## Step 7: Resource Whitelists and Blacklists

### 7.1 Create Project with Resource Restrictions

Create `restricted-project.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: restricted
  namespace: argocd
spec:
  description: Restricted project - limited resource types
  
  sourceRepos:
  - '*'  # All repos allowed
  
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  
  # Only allow specific resources
  namespaceResourceWhitelist:
  - group: 'apps'
    kind: Deployment
  - group: ''
    kind: Service
  - group: ''
    kind: ConfigMap
  
  # Deny dangerous resources
  namespaceResourceBlacklist:
  - group: ''
    kind: Secret
  - group: 'rbac.authorization.k8s.io'
    kind: '*'
```

### 7.2 Apply Restricted Project

```bash
kubectl apply -f restricted-project.yaml
```

### 7.3 Test Resource Restrictions

Try to deploy an app with a Secret:

```bash
# This will fail because Secrets are blacklisted
argocd app create restricted-test \
  --project restricted \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

If the app has secrets, sync will fail with permission error.

---

## Step 8: Sync Windows

Control when syncs are allowed (e.g., business hours only).

### 8.1 Add Sync Window to Project

Create `project-with-sync-window.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: scheduled
  namespace: argocd
spec:
  description: Project with sync windows
  
  sourceRepos:
  - '*'
  
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  
  # Define sync windows
  syncWindows:
  - kind: allow
    schedule: '0 9 * * 1-5'  # 9 AM on weekdays
    duration: 8h             # 8-hour window
    applications:
    - '*'
    namespaces:
    - production
  - kind: deny
    schedule: '0 0 * * 0,6'  # Weekends
    duration: 24h
    applications:
    - '*'
    namespaces:
    - production
```

### 8.2 Apply Configuration

```bash
kubectl apply -f project-with-sync-window.yaml
```

---

## Step 9: Project Roles and RBAC

### 9.1 Create Project with Roles

Create `team-a-with-roles.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-a-rbac
  namespace: argocd
spec:
  description: Team A with RBAC roles
  
  sourceRepos:
  - '*'
  
  destinations:
  - namespace: team-a
    server: https://kubernetes.default.svc
  
  # Define roles
  roles:
  # Developers can view and sync
  - name: developer
    description: Developers for Team A
    policies:
    - p, proj:team-a-rbac:developer, applications, get, team-a-rbac/*, allow
    - p, proj:team-a-rbac:developer, applications, sync, team-a-rbac/*, allow
    groups:
    - team-a-developers
  
  # Admins can do everything
  - name: admin
    description: Admins for Team A
    policies:
    - p, proj:team-a-rbac:admin, applications, *, team-a-rbac/*, allow
    groups:
    - team-a-admins
  
  # Viewers can only read
  - name: viewer
    description: Viewers for Team A
    policies:
    - p, proj:team-a-rbac:viewer, applications, get, team-a-rbac/*, allow
    groups:
    - team-a-viewers
```

### 9.2 Apply RBAC Project

```bash
kubectl apply -f team-a-with-roles.yaml
```

### 9.3 Generate Role Token

```bash
argocd proj role create-token team-a-rbac developer
```

This creates a JWT token for the developer role.

---

## Step 10: Wildcard Patterns

### 10.1 Use Wildcards for Flexibility

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: multi-team
  namespace: argocd
spec:
  sourceRepos:
  - https://github.com/myorg/*        # All repos in org
  - https://github.com/*/charts       # Charts repos
  
  destinations:
  - namespace: 'team-*'                # All team namespaces
    server: https://kubernetes.default.svc
  - namespace: 'dev-*'                 # All dev namespaces
    server: https://kubernetes.default.svc
```

---

## Step 11: Project Quotas

### 11.1 Set Resource Quotas

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: quota-project
  namespace: argocd
spec:
  sourceRepos:
  - '*'
  
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  
  # Orphaned resources cleanup
  orphanedResources:
    warn: true
    ignore:
    - group: ''
      kind: ConfigMap
      name: special-config
```

---

## Exercises

### Exercise 1: Create a Read-Only Project

Create a project where applications can only be viewed, not synced:

```yaml
roles:
- name: readonly
  policies:
  - p, proj:readonly:readonly, applications, get, */*, allow
  - p, proj:readonly:readonly, applications, sync, */*, deny
```

### Exercise 2: Multi-Environment Project

Create a project supporting dev, staging, prod namespaces with different restrictions.

### Exercise 3: Implement Team Isolation

Set up 3 teams with complete isolation:
- Each team has their own namespaces
- Teams can only use their Git repos
- Cross-team deployments are blocked

---

## Verification Checklist

- [ ] Created custom AppProjects
- [ ] Restricted destinations work
- [ ] Source repo restrictions work
- [ ] Resource whitelists enforced
- [ ] Resource blacklists enforced
- [ ] Sync windows configured
- [ ] Project roles created
- [ ] Tested RBAC policies

---

## Troubleshooting

### Problem: Can't create application in project

**Solution:** Check project permissions:
```bash
argocd proj get <project-name>
```

Verify:
- Destination namespace is allowed
- Source repo is whitelisted
- Resource types are permitted

### Problem: Sync blocked by window

**Solution:** Check sync windows:
```bash
argocd proj windows list <project-name>
```

Or bypass (if you have override permission):
```bash
argocd app sync <app-name> --force
```

---

## Clean Up

```bash
argocd app delete team-a-guestbook
argocd app delete team-b-guestbook
kubectl delete namespace team-a team-b shared
argocd proj delete team-a team-b restricted scheduled
```

---

## What's Next?

Proceed to:
- **[Lab 5: App of Apps Pattern](../lab-05-app-of-apps/README.md)**

---

## Key Takeaways

✅ AppProjects provide multi-tenancy in Argo CD  
✅ Projects restrict repos, destinations, and resources  
✅ Whitelists and blacklists control resource types  
✅ Sync windows enable maintenance schedules  
✅ Project roles enable fine-grained RBAC  
✅ Wildcards provide flexible pattern matching
