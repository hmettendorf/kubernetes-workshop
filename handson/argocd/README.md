# Argo CD Hands-On Labs

This directory contains hands-on exercises for learning Argo CD and GitOps practices.

## Lab Structure

Each lab is self-contained with:
- **Instructions** - Step-by-step guide
- **Example files** - Sample manifests and configurations
- **Solutions** - Reference implementations

## Prerequisites

Before starting these labs, ensure you have:
- Access to a Kubernetes cluster (local or remote)
- `kubectl` installed and configured
- `helm` v3+ installed
- Git installed
- Basic understanding of Kubernetes concepts

## Labs Overview

### Lab 1: Installation & Setup (30 minutes)
Install Argo CD on your Kubernetes cluster and set up CLI access.

**What you'll learn:**
- Installing Argo CD using kubectl
- Accessing the Argo CD UI
- Installing and configuring the Argo CD CLI
- Logging in and basic navigation

[Go to Lab 1 →](./lab-01-installation/README.md)

---

### Lab 2: Your First Application (45 minutes)
Deploy your first application using Argo CD from a Git repository.

**What you'll learn:**
- Creating an Application manifest
- Connecting to Git repositories
- Manual sync operations
- Viewing application status and resources
- Troubleshooting sync issues

[Go to Lab 2 →](./lab-02-first-application/README.md)

---

### Lab 3: Drift Detection & Self-Healing (30 minutes)
Experiment with drift detection and automated reconciliation.

**What you'll learn:**
- Understanding drift detection
- Making manual changes to resources
- Observing Argo CD's detection mechanisms
- Enabling self-healing (selfHeal)
- Testing automated rollback

[Go to Lab 3 →](./lab-03-drift-detection/README.md)

---

### Lab 4: AppProjects & Multi-Tenancy (45 minutes)
Set up multi-tenancy using AppProjects with RBAC.

**What you'll learn:**
- Creating AppProjects
- Restricting source repositories
- Limiting destination namespaces
- Configuring resource whitelists/blacklists
- Simulating team isolation

[Go to Lab 4 →](./lab-04-appprojects/README.md)

---

### Lab 5: App of Apps Pattern (60 minutes)
Implement the App of Apps pattern to manage multiple applications.

**What you'll learn:**
- Understanding the App of Apps pattern
- Creating a root application
- Deploying child applications automatically
- Managing application dependencies
- Bootstrapping entire environments

[Go to Lab 5 →](./lab-05-app-of-apps/README.md)

---

### Lab 6: Environment Promotion (60 minutes)
Set up multiple environments and practice GitOps-based promotion.

**What you'll learn:**
- Environment strategies (branches vs directories)
- Using Kustomize overlays
- Using Helm with environment-specific values
- Promoting changes through environments
- Rollback strategies

[Go to Lab 6 →](./lab-06-environment-promotion/README.md)

---

## Bonus Labs (Optional)

### Bonus Lab 1: Helm Integration
Deep dive into using Helm charts with Argo CD.

[Go to Bonus Lab 1 →](./bonus-lab-01-helm/README.md)

---

### Bonus Lab 2: Sync Waves & Hooks
Learn about controlling deployment order and lifecycle hooks.

[Go to Bonus Lab 2 →](./bonus-lab-02-sync-waves/README.md)

---

### Bonus Lab 3: Notifications & Webhooks
Set up notifications for deployment events.

[Go to Bonus Lab 3 →](./bonus-lab-03-notifications/README.md)

---

## Lab Environment

### Option 1: Local Cluster (Recommended for Workshop)

Use `kind` (Kubernetes in Docker) or `minikube`:

```bash
# Using kind
kind create cluster --name argocd-workshop

# Using minikube
minikube start --cpus=4 --memory=8192
```

### Option 2: Cloud Cluster

You can use any cloud Kubernetes service:
- Google Kubernetes Engine (GKE)
- Azure Kubernetes Service (AKS)
- Amazon Elastic Kubernetes Service (EKS)

### Verify Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
```

---

## Clean Up

After completing the labs:

```bash
# Delete the Argo CD namespace
kubectl delete namespace argocd

# Delete the local cluster (if using kind)
kind delete cluster --name argocd-workshop

# Or stop minikube
minikube stop
```

---

## Troubleshooting

### Common Issues

**Issue: Cannot access Argo CD UI**
```bash
# Check if port-forward is running
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Issue: Argo CD CLI login fails**
```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Issue: Application stuck in Progressing state**
```bash
# Check application status
argocd app get <app-name>

# View detailed events
kubectl get events -n <namespace>
```

---

## Additional Resources

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [Argo CD GitHub](https://github.com/argoproj/argo-cd)
- [Argo CD Slack](https://cloud-native.slack.com/channels/argo-cd)

---

## Feedback

We'd love to hear your feedback on these labs! Please open an issue or submit a pull request.
