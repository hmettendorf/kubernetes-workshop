# Quick Start Guide

Get started with the Argo CD workshop in 5 minutes!

## Prerequisites Check

```bash
# Check kubectl
kubectl version --client

# Check helm
helm version

# Check cluster access
kubectl cluster-info
```

## Step 1: Install Argo CD (5 minutes)

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## Step 2: Access Argo CD UI

```bash
# Port forward (in a separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

Open browser: https://localhost:8080
- Username: `admin`
- Password: (from command above)

## Step 3: Install CLI

**macOS:**
```bash
brew install argocd
```

**Linux:**
```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

## Step 4: Deploy First App

```bash
# Login via CLI
argocd login localhost:8080

# Create application
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync application
argocd app sync guestbook

# Check status
argocd app get guestbook
```

## Step 5: View in UI

1. Go to https://localhost:8080
2. Click on "guestbook" application
3. Explore the resource tree

## What's Next?

Now you're ready for the full labs:
- [Lab 1: Installation & Setup](./lab-01-installation/README.md)
- [Lab 2: Your First Application](./lab-02-first-application/README.md)
- [Lab 3: Drift Detection](./lab-03-drift-detection/README.md)
- [Lab 4: AppProjects](./lab-04-appprojects/README.md)
- [Lab 5: App of Apps](./lab-05-app-of-apps/README.md)

## Common Commands Cheat Sheet

```bash
# Application management
argocd app list
argocd app get <app-name>
argocd app sync <app-name>
argocd app delete <app-name>

# View logs
argocd app logs <app-name>

# View diff
argocd app diff <app-name>

# Project management
argocd proj list
argocd proj get <project-name>

# Cluster management
argocd cluster list
```

## Troubleshooting

**Can't access UI?**
```bash
# Check if port-forward is running
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Forgot password?**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Application stuck?**
```bash
argocd app get <app-name>
kubectl get events -n <namespace>
```

## Clean Up

```bash
# Delete applications
argocd app delete guestbook

# Delete Argo CD
kubectl delete namespace argocd
```

---

**Ready to dive deeper? Start with [Lab 1](./lab-01-installation/README.md)!**
