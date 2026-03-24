# 🧭 Kubernetes Workshop: From Basics to Production

A comprehensive 3-day workshop covering Kubernetes application packaging, GitOps deployment with Argo CD, security, and observability.

> 💡 **New:** Presentations are now automatically converted to PDF! Check [Releases](../../releases) for downloadable workshop packages.

---

## 👥 Target Audience

This workshop is designed for **engineers with basic Kubernetes knowledge** including:

- Understanding of pods, services, and deployments
- Familiarity with Git and CLI tools
- Basic container concepts

## 📋 Workshop Format

- **30-40% Theory** - Core concepts and best practices
- **60-70% Hands-on Labs** - Practical exercises and real-world scenarios
- **Short Demos** - Guided examples and demonstrations
- **End-of-Day Recap** - Review and optional challenges

---

## 📅 Day 1 – Packaging, Deployment & Developer Workflow (8h)

Led by Holger Tiemeyer

---

## 📅 Day 2 – GitOps with Argo CD (4.5h)

**Environment:** Rancher Desktop with k3s  
**Demo Application:** [Google Cloud Microservices Demo](https://github.com/GoogleCloudPlatform/microservices-demo)

### 09:00 – 09:30 | GitOps Concepts & Environment Setup

**Concepts:**

- What is GitOps?
- Declarative vs imperative
- Desired state & reconciliation
- Git as source of truth

**Setup:**

- Verify Rancher Desktop with k3s
- Tooling check: `kubectl`, `helm`, `argocd` CLI
- Fork/clone workshop seed repository

### 09:30 – 10:30 | Argo CD – Installation & First Application

**Concepts:**

- Argo CD architecture & components
- Installation via Helm chart
- Application manifests
- Sync strategies & health status

**Lab 01 - Installation:**

- Install Argo CD via Helm (`oci://ghcr.io/argoproj/argo-helm/argo-cd`)
- Access UI & CLI
- Configure admin access

**Lab 02 - First Application:**

- Deploy microservices-demo via Argo CD
- Connect personal Git branch
- Observe deployment and health checks
- Access the application

### 10:30 – 11:30 | Drift Detection & Reconciliation

**Concepts:**

- Desired vs actual state
- Auto-sync vs manual sync
- Self-healing capabilities
- Sync waves and hooks

**Lab 03 - Drift Detection:**

- Make manual changes via `kubectl`
- Observe drift in Argo CD
- Enable auto-sync and self-healing
- Test reconciliation behavior

### 11:30 – 12:30 | ☕ Lunch Break

### 12:30 – 13:30 | ApplicationSets & Advanced Patterns

**Concepts:**

- ApplicationSets for multi-environment deployment
- Generators (List, Git, Cluster)
- Template parameters
- App of Apps pattern

**Lab 04 - ApplicationSets:**

- Create ApplicationSet for microservices-demo
- Deploy to multiple namespaces
- Use Git generator for dynamic configuration

**Lab 05 - App of Apps:**

- Implement App of Apps pattern
- Manage multiple applications
- Environment promotion workflow

### 13:30 – 14:30 | Bonus Content & Wrap-Up

**Bonus Lab 01 - Prometheus Integration (Optional):**

- Expose application metrics
- Monitor Argo CD with Prometheus
- Basic PromQL queries for GitOps metrics

**Bonus Lab 02 - Argo Rollouts (Optional):**

- Introduction to progressive delivery
- Blue/Green deployment strategy
- Canary deployments with traffic splitting

**Wrap-Up:**

- GitOps best practices
- Argo CD troubleshooting tips
- Q&A

---

## 📅 Day 3 – Security & Observability (8h)

Led by Holger Tiemeyer

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following tools installed:

- `kubectl` (v1.24+)
- `helm` (v3.10+)
- Access to a Kubernetes cluster
- Container registry credentials

### Quick Setup

```bash
# Clone this repository
git clone <repo-url>
cd argocd-workshop

# Verify cluster access
kubectl cluster-info

# Check tool versions
kubectl version --client
helm version
```
