# Argo CD Hands-On Labs

This directory contains hands-on exercises for learning Argo CD and GitOps practices.

## Lab Structure

Each lab is self-contained with:
- **Instructions** - Step-by-step guide
- **Example files** - Sample manifests and configurations
- **Solutions** - Reference implementations

## Prerequisites

Before starting these labs, ensure you have:
- Rancher Desktop with k3s installed (see Lab Environment below)
- `kubectl` installed and configured
- `argocd` CLI installed
- Git installed
- SSH key generated and added to GitHub deploy keys
- Basic understanding of Kubernetes concepts

## Workshop Schedule (Day 2)

**Duration:** 9:00 - 14:30 (with 1 hour lunch break)

- **9:00 - 10:00** - Lab 1: Installation & Setup
- **10:00 - 11:15** - Lab 2: Your First Application (Microservices Demo)
- **11:15 - 12:00** - Lab 3: Drift Detection & Self-Healing
- **12:00 - 13:00** - **Lunch Break**
- **13:00 - 14:00** - Lab 4: ApplicationSets
- **14:00 - 14:30** - Lab 5: App of Apps Pattern

---

## Labs Overview

### Lab 1: Installation & Setup (60 minutes)
Install Argo CD on Rancher Desktop with k3s and set up CLI access.

**What you'll learn:**
- Installing Argo CD using kubectl on k3s
- Accessing the Argo CD UI
- Installing and configuring the Argo CD CLI
- Logging in and basic navigation

[Go to Lab 1 →](./lab-01-installation/README.md)

---

### Lab 2: Your First Application (75 minutes)
Deploy Google Cloud's microservices demo application using Argo CD from a Git repository.

**What you'll learn:**
- Creating an Application manifest
- Connecting to Git repositories
- Deploying a multi-service microservices application
- Manual sync operations
- Viewing application status and resources
- Troubleshooting sync issues

[Go to Lab 2 →](./lab-02-first-application/README.md)

---

### Lab 3: Drift Detection & Self-Healing (45 minutes)
Experiment with drift detection and automated reconciliation.

**What you'll learn:**
- Understanding drift detection
- Making manual changes to resources
- Observing Argo CD's detection mechanisms
- Enabling self-healing (selfHeal)
- Testing automated rollback

[Go to Lab 3 →](./lab-03-drift-detection/README.md)

---

### Lab 4: ApplicationSets (60 minutes)
Use ApplicationSets to manage multiple applications with automation and templating.

**What you'll learn:**
- Understanding ApplicationSet patterns
- List generator for multiple environments
- Git generator for repository-based apps
- Matrix generator for complex scenarios
- Templating applications at scale

[Go to Lab 4 →](./lab-04-applicationsets/README.md)

---

### Lab 5: App of Apps Pattern (30 minutes)
Implement the App of Apps pattern to manage multiple applications.

**What you'll learn:**
- Understanding the App of Apps pattern
- Creating a root application
- Deploying child applications automatically
- Managing application dependencies
- Bootstrapping entire environments

[Go to Lab 5 →](./lab-05-app-of-apps/README.md)

---

## Bonus Labs (Optional)

### Bonus Lab 1: Prometheus Metrics
Monitor Argo CD with Prometheus and understand GitOps metrics.

**What you'll learn:**
- Enabling Argo CD metrics
- Deploying Prometheus
- Viewing sync metrics
- Application health metrics
- Creating alerts for sync failures

[Go to Bonus Lab 1 →](./bonus-lab-01-prometheus/README.md)

---

### Bonus Lab 2: Argo Rollouts - Blue/Green Deployments
Implement progressive delivery with Argo Rollouts.

**What you'll learn:**
- Installing Argo Rollouts
- Blue/Green deployment strategy
- Canary deployments
- Analysis and automated rollback
- Traffic management

[Go to Bonus Lab 2 →](./bonus-lab-02-rollouts/README.md)

---

## Additional Labs (If Time Permits)

### Lab 6: Environment Promotion
Set up multiple environments and practice GitOps-based promotion.

**What you'll learn:**
- Environment strategies (branches vs directories)
- Using Kustomize overlays
- Using Helm with environment-specific values
- Promoting changes through environments
- Rollback strategies

[Go to Lab 6 →](./lab-06-environment-promotion/README.md)

---

## Original Labs (Reference)

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

### Rancher Desktop with k3s (Workshop Environment)

We'll use **Rancher Desktop** with the **k3s** Kubernetes distribution for this workshop.

#### Prerequisites

1. **Install Rancher Desktop:**
   - Download from: https://rancherdesktop.io/
   - Follow installation instructions for your OS
   - Select **k3s** as the Kubernetes engine during setup
   - Recommended settings:
     - Memory: 8GB
     - CPUs: 4

2. **Verify Installation:**

```bash
# Check Rancher Desktop is running
kubectl cluster-info

# Verify k3s nodes
kubectl get nodes

# Check available resources
kubectl get namespaces
```

---

## GitOps Workflow with Seeds Repository

This workshop follows a true GitOps approach using a dedicated seeds repository.

### Setup

1. **Generate SSH Key** (if you don't have one):
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

2. **Send Your Public Key** to the instructor:
```bash
cat ~/.ssh/id_ed25519.pub
```

3. **Clone the Seeds Repository:**
```bash
git clone git@github.com:hmettendorf/kubernetes-workshop-seeds.git
cd kubernetes-workshop-seeds
```

4. **Create Your Branch:**
```bash
# Replace <username> with your assigned username
git checkout -b member/<username>
git push -u origin member/<username>
```

### Workflow During Labs

Throughout the workshop, you'll:

1. **Copy** lab examples from this workshop repository to your seeds repository
2. **Commit and push** changes to your branch
3. **Configure ArgoCD** to watch your branch
4. **Observe** ArgoCD automatically deploying your changes

**Example:**
```bash
# In the seeds repository
cd kubernetes-workshop-seeds

# Copy a lab example
cp ../kubernetes-workshop/handson/argocd/lab-02-first-application/application.yaml ./

# Commit and push
git add application.yaml
git commit -m "Add microservices demo application"
git push

# ArgoCD will automatically detect and deploy!
```

### Benefits

- ✅ True GitOps: Git is the single source of truth
- ✅ Each participant has their own isolated branch
- ✅ No cluster resource conflicts (each participant has their own cluster)
- ✅ Practice real-world GitOps workflows
- ✅ Simple: just copy, commit, push - no complex scripts!

---

## Clean Up

After completing the labs:

```bash
# Delete the Argo CD namespace
kubectl delete namespace argocd

# If you created other namespaces during labs
kubectl delete namespace microservices-demo

# Rancher Desktop cleanup
# Simply stop Rancher Desktop via the UI, or reset Kubernetes cluster
# Settings → Kubernetes → Reset Kubernetes
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
