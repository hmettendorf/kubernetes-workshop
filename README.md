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

### 09:00 – 09:30 | Welcome & Environment Setup

**Topics:**

- Workshop goals & structure
- Cluster access (local / managed)
- Tooling check: `kubectl`, `helm`, `skaffold`, container registry access
- Repo overview (labs & solutions)

### 09:30 – 10:30 | Kubernetes Application Recap (Fast)

**Concepts:**

- Deployment anatomy
- ConfigMaps & Secrets
- Services & Ingress (quick overview)

**Lab:**

- Deploy a baseline demo application manually
- Inspect resources and logs

### 10:30 – 12:00 | Helm – Fundamentals

**Concepts:**

- Why Helm?
- Chart structure
- Templates & values
- Releases and upgrades
- Helm lifecycle

**Lab:**

- Install an existing Helm chart
- Explore rendered manifests
- Modify values and upgrade release

### 12:00 – 13:00 | ☕ Lunch Break

### 13:00 – 14:30 | Helm – Advanced Usage

**Concepts:**

- Template functions & conditionals
- Values layering (env-specific configs)
- Hooks
- Dependencies & subcharts
- Best practices for chart design

**Lab:**

- Create a Helm chart for the demo app
- Add configurable resources, replicas, env vars
- Introduce environment-specific values

### 14:30 – 14:45 | ☕ Break

### 14:45 – 16:15 | Skaffold – Local Dev to Cluster

**Concepts:**

- Problem Skaffold solves
- Build → tag → deploy workflow
- Skaffold profiles
- Integration with Helm

**Lab:**

- Create a `skaffold.yaml`
- Enable live reload / sync
- Use profiles for dev vs prod
- Deploy Helm charts via Skaffold

### 16:15 – 17:00 | Day 1 Wrap-Up

- Common pitfalls
- Helm + Skaffold workflow recap
- Q&A
- **Optional challenge:** Add a second service via Helm

---

## 📅 Day 2 – GitOps with Argo CD (8h)

### 09:00 – 09:30 | GitOps Concepts

**Concepts:**

- What is GitOps?
- Declarative vs imperative
- Desired state & reconciliation
- Git as source of truth

### 09:30 – 10:45 | Argo CD – Installation & Architecture

**Concepts:**

- Argo CD components
- App vs AppProject
- Sync strategies
- Drift detection

**Lab:**

- Install Argo CD
- Access UI & CLI
- Explore built-in applications

### 10:45 – 12:00 | Argo CD Applications

**Concepts:**

- Application manifests
- Helm + Kustomize support
- Sync options (manual vs auto)
- Health & sync status

**Lab:**

- Deploy the demo app via Argo CD
- Connect Git repo
- Trigger syncs via Git commits
- Observe drift & reconciliation

### 12:00 – 13:00 | ☕ Lunch Break

### 13:00 – 14:30 | AppProjects & Multi-Tenancy

**Concepts:**

- AppProjects
- RBAC boundaries in Argo CD
- Cluster & namespace scoping
- Repo & destination restrictions

**Lab:**

- Create AppProjects
- Restrict namespaces & repos
- Assign applications to projects
- Simulate multi-team setup

### 14:30 – 14:45 | ☕ Break

### 14:45 – 16:15 | Advanced GitOps Patterns

**Concepts:**

- App of Apps pattern
- Environment promotion (dev → prod)
- Helm values per environment
- Secrets handling (high-level)

**Lab:**

- Implement App of Apps pattern
- Split environments
- Promote changes via Git only

### 16:15 – 17:00 | Day 2 Wrap-Up

- GitOps anti-patterns
- Argo CD troubleshooting
- Q&A
- **Optional challenge:** Auto-sync with rollback

---

## 📅 Day 3 – Security & Observability (8h)

### 09:00 – 10:30 | Kubernetes Security – RBAC

**Concepts:**

- Authentication vs Authorization
- Roles & ClusterRoles
- RoleBindings
- Least privilege principle

**Lab:**

- Create service accounts
- Define roles & bindings
- Restrict access to namespaces
- Test permissions with `kubectl auth can-i`

### 10:30 – 12:00 | Kubernetes Security – Network Policies

**Concepts:**

- Default allow vs default deny
- Ingress & egress rules
- Namespace isolation
- Common pitfalls

**Lab:**

- Apply default deny policy
- Allow app-to-app traffic
- Break & fix connectivity
- Visualize traffic flows

### 12:00 – 13:00 | ☕ Lunch Break

### 13:00 – 14:30 | Monitoring – Prometheus

**Concepts:**

- Metrics vs logs vs traces
- Prometheus architecture
- Service discovery
- Scraping & labels

**Lab:**

- Install Prometheus stack
- Explore metrics
- Expose app metrics
- Write basic PromQL queries

### 14:30 – 14:45 | ☕ Break

### 14:45 – 16:15 | Monitoring – Grafana

**Concepts:**

- Dashboards & panels
- Data sources
- Alerts (overview)

**Lab:**

- Connect Grafana to Prometheus
- Import dashboards
- Build a custom app dashboard
- Create a basic alert

### 16:15 – 17:00 | Final Wrap-Up & Next Steps

**End-to-end workflow recap:**

```
Dev → Helm → Skaffold → Git → Argo CD → Secure → Monitor
```

**Production readiness checklist**

**Recommended next topics:**

- Secrets management
- Policy as code
- Tracing & SLOs

**Final Q&A**

---

## 🧪 Optional Extras (If Time Allows)

- Helm linting & testing
- Argo CD notifications
- RBAC + GitOps integration
- Prometheus alert routing

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following tools installed:

- `kubectl` (v1.24+)
- `helm` (v3.10+)
- `skaffold` (v2.0+)
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
skaffold version
```
