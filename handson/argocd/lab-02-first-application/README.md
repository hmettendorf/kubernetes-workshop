# Lab 2: Your First Application

## Overview

Deploy your first application using Argo CD, connecting to a Git repository and managing the application lifecycle.

**Duration:** 45 minutes

**Learning Objectives:**
- Create an Argo CD Application resource
- Connect to Git repositories
- Perform manual sync operations
- Monitor application health and sync status
- Use the Argo CD UI and CLI

---

## Prerequisites

- Completed Lab 1 (Argo CD installed)
- Argo CD CLI logged in
- Access to the Argo CD UI

---

## Step 1: Prepare Demo Application

We'll deploy a simple guestbook application. First, let's examine what we'll be deploying.

### 1.1 Review Application Manifests

The demo application consists of:
- **Deployment** - Frontend application
- **Service** - Expose the frontend

Create a directory for our manifests:

```bash
mkdir -p ~/argocd-demo-app
cd ~/argocd-demo-app
```

### 1.2 Create Application Manifests

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook-ui
  labels:
    app: guestbook-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: guestbook-ui
  template:
    metadata:
      labels:
        app: guestbook-ui
    spec:
      containers:
      - name: guestbook-ui
        image: gcr.io/heptio-images/ks-guestbook-demo:0.2
        ports:
        - containerPort: 80
```

Create `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
  labels:
    app: guestbook-ui
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: guestbook-ui
```

### 1.3 Initialize Git Repository (Simulation)

For this lab, we'll use Argo CD's example repository. In production, you'd push these to your own Git repo.

We'll use: `https://github.com/argoproj/argocd-example-apps`

---

## Step 2: Create Application via CLI

### 2.1 Create the Application

```bash
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

**Command breakdown:**
- `guestbook` - Application name
- `--repo` - Git repository URL
- `--path` - Path within the repo containing manifests
- `--dest-server` - Target Kubernetes cluster
- `--dest-namespace` - Target namespace

### 2.2 Verify Application Created

```bash
argocd app list
```

Output should show:
```
NAME       CLUSTER                         NAMESPACE  PROJECT  STATUS     HEALTH   SYNCPOLICY  CONDITIONS
guestbook  https://kubernetes.default.svc  default    default  OutOfSync  Missing  <none>      <none>
```

Notice:
- **STATUS: OutOfSync** - Git state differs from cluster state
- **HEALTH: Missing** - Resources don't exist in cluster yet

### 2.3 View Application Details

```bash
argocd app get guestbook
```

This shows:
- Source (Git repo and path)
- Destination (cluster and namespace)
- Resources to be created
- Sync status

---

## Step 3: Sync the Application

### 3.1 Manual Sync via CLI

Sync the application to deploy resources:

```bash
argocd app sync guestbook
```

Watch the sync progress. You'll see:
- Resources being created
- Health status changing from Missing → Progressing → Healthy

### 3.2 Verify Deployment

Check the application status:

```bash
argocd app get guestbook
```

Now you should see:
- **STATUS: Synced**
- **HEALTH: Healthy**

Verify resources in Kubernetes:

```bash
kubectl get all -n default -l app=guestbook-ui
```

You should see:
- Deployment
- ReplicaSet
- Pod (Running)
- Service

---

## Step 4: Explore the Argo CD UI

### 4.1 View Application in UI

1. Open the Argo CD UI: `https://localhost:8080`
2. Click on the **guestbook** application

### 4.2 Explore Application View

The UI shows:
- **Top bar** - Sync status, health, repo info
- **Graph view** - Visual representation of resources
- **Resource tree** - Hierarchical view of all resources
- **Details panel** - Resource-specific information

### 4.3 Navigate the Resource Tree

Click on different resources to see:
- YAML definitions
- Events
- Logs (for Pods)
- Diffs (when out of sync)

---

## Step 5: Make Changes in Git

Let's simulate a configuration change.

### 5.1 View Current Replicas

```bash
kubectl get deployment guestbook-ui -n default
```

Current replicas: 1

### 5.2 Understanding Application Updates

In a real scenario, you would:
1. Fork the repository
2. Modify `deployment.yaml` (e.g., change replicas to 2)
3. Commit and push changes
4. Argo CD detects changes automatically (or manual sync)

For this lab, we'll demonstrate the sync process without forking.

---

## Step 6: Create Application via UI

Let's create another application using the UI.

### 6.1 Create New Application

1. Click **+ NEW APP** button
2. Fill in the form:
   - **Application Name:** `guestbook-ui`
   - **Project:** `default`
   - **Sync Policy:** `Manual`
   - **Repository URL:** `https://github.com/argoproj/argocd-example-apps.git`
   - **Revision:** `HEAD`
   - **Path:** `helm-guestbook`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `guestbook`

3. Click **CREATE**

### 6.2 Sync via UI

1. Click the **SYNC** button
2. In the sync panel, review resources to be created
3. Click **SYNCHRONIZE**

Watch the sync progress in the UI.

---

## Step 7: Explore Application Resources

### 7.1 View Pod Logs

**Via CLI:**
```bash
argocd app logs guestbook
```

**Via UI:**
1. Click on the Pod resource
2. Select the **LOGS** tab

### 7.2 View Resource Details

**Via CLI:**
```bash
# Get specific resource
kubectl get deployment guestbook-ui -n default -o yaml

# View events
kubectl get events -n default --sort-by='.lastTimestamp'
```

**Via UI:**
- Click any resource in the tree
- View **SUMMARY**, **EVENTS**, **MANIFEST** tabs

### 7.3 View Application History

```bash
argocd app history guestbook
```

Shows:
- Revision number
- Deployed at timestamp
- Git commit SHA

---

## Step 8: Application Refresh and Hard Refresh

### 8.1 Refresh Application

Refresh fetches latest state from Git:

```bash
argocd app get guestbook --refresh
```

This compares Git with cluster without making changes.

### 8.2 Hard Refresh

Hard refresh also clears the cache:

```bash
argocd app get guestbook --hard-refresh
```

---

## Step 9: Delete Application Resources

### 9.1 Delete Application (Cascade)

Delete the application and all its resources:

```bash
argocd app delete guestbook
```

Confirm with `y`.

This deletes:
- The Application CR in Argo CD
- All Kubernetes resources deployed by the app

### 9.2 Delete Application (Non-Cascade)

To delete only the Argo CD Application (keeping resources in cluster):

```bash
argocd app delete guestbook --cascade=false
```

---

## Step 10: Create Application Declaratively

The GitOps way: define Application as YAML.

### 10.1 Create Application Manifest

Create `guestbook-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
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
      prune: false
      selfHeal: false
```

### 10.2 Apply the Application

```bash
kubectl apply -f guestbook-app.yaml
```

### 10.3 Verify Creation

```bash
argocd app list
kubectl get applications -n argocd
```

Both commands should show the guestbook application.

### 10.4 Sync the Application

```bash
argocd app sync guestbook
```

---

## Exercises

Try these challenges:

### Exercise 1: Change Sync Policy
Modify the application to use automated sync:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

Apply changes:
```bash
kubectl apply -f guestbook-app.yaml
```

### Exercise 2: Deploy Another Application
Create a new application using the `helm-guestbook` path.

### Exercise 3: Explore Different Paths
Try deploying applications from different paths in the example repo:
- `kustomize-guestbook`
- `helm-guestbook`
- `ksonnet-guestbook`

---

## Verification Checklist

- [ ] Application created successfully
- [ ] Application synced and healthy
- [ ] Resources deployed to Kubernetes
- [ ] Can view application in UI
- [ ] Can view logs and events
- [ ] Understand sync vs refresh
- [ ] Created application declaratively

---

## Troubleshooting

### Problem: Application stuck in Progressing

**Solution:** Check pod status:
```bash
kubectl get pods -n default
kubectl describe pod <pod-name> -n default
```

### Problem: Sync fails with permission error

**Solution:** Check namespace exists:
```bash
kubectl create namespace default  # if it doesn't exist
```

### Problem: Can't find resources in UI

**Solution:** Click the refresh button or:
```bash
argocd app get guestbook --refresh
```

---

## Clean Up

Remove the guestbook application:

```bash
argocd app delete guestbook
```

Or keep it for the next lab!

---

## What's Next?

Proceed to:
- **[Lab 3: Drift Detection & Self-Healing](../lab-03-drift-detection/README.md)**

---

## Key Takeaways

✅ Applications are the core resource in Argo CD  
✅ Applications connect Git repos to Kubernetes clusters  
✅ Sync operations deploy changes from Git to cluster  
✅ Both CLI and UI provide full management capabilities  
✅ Declarative application definitions enable GitOps
