# Lab 4: ApplicationSets

## Overview

Learn how to use ApplicationSets to automate the creation and management of multiple Argo CD Applications using templating and generators.

**Duration:** 60 minutes

**Learning Objectives:**
- Understand ApplicationSet concepts and use cases
- Use List generator for multiple environments
- Use Git generator for repository-based automation
- Use Cluster generator for multi-cluster deployments
- Implement Matrix generator for complex scenarios
- Template applications at scale

---

## Prerequisites

- Completed Labs 1-3
- Microservices demo application deployed
- Understanding of Argo CD Applications

---

## What are ApplicationSets?

**ApplicationSets** provide a way to automatically generate Argo CD Applications using templates and generators. They enable:

- **Multi-environment deployments** - Deploy to dev, staging, prod automatically
- **Multi-cluster management** - Deploy to multiple clusters from one definition
- **Monorepo support** - Automatically create apps from multiple directories in a repo
- **Dynamic application creation** - Generate apps based on Git repository structure

### Key Components

1. **Generators** - Determine which Applications to create
2. **Template** - Defines how each Application should be configured
3. **Parameters** - Variables passed from generator to template

---

## Step 1: Understanding ApplicationSet Generators

### 1.1 View ApplicationSet CRD

Check if ApplicationSets are available:

```bash
kubectl get crd applicationsets.argoproj.io
```

ApplicationSets are included in Argo CD by default (v2.3+).

### 1.2 List Existing ApplicationSets

```bash
kubectl get applicationsets -n argocd
```

Currently should show no ApplicationSets.

---

## Step 2: List Generator - Deploy Microservices to Multiple Environments

### 2.1 Create ApplicationSet Manifest

Copy the example ApplicationSet to your seeds repository:

```bash
# Go to your seeds repository
cd ~/kubernetes-workshop-seeds

# Copy the ApplicationSet example
cp ~/kubernetes-workshop/handson/argocd/lab-04-applicationsets/appset-microservices-environments.yaml .
```

### 2.2 Review the ApplicationSet

Let's examine what this ApplicationSet does:

```bash
cat appset-microservices-environments.yaml
```

**Key features:**
- Uses List generator to define 3 environments: dev, staging, prod
- Istio features disabled via Helm values
- Automatic sync enabled for all environments
- Each environment isolated in its own namespace
- Creates namespaces automatically

The ApplicationSet will generate 3 Applications:
- `shop-dev` → deploys to `shop-dev` namespace
- `shop-staging` → deploys to `shop-staging` namespace
- `shop-prod` → deploys to `shop-prod` namespace

### 2.3 Commit and Push

```bash
# Add the file
git add appset-microservices-environments.yaml

# Commit
git commit -m "Lab 4: Add multi-environment ApplicationSet"

# Push to your branch
git push
```

### 2.4 Apply the ApplicationSet

```bash
kubectl apply -f appset-microservices-environments.yaml
```

### 2.5 Verify Applications Created via UI

In the UI:
1. Go to the **Applications** view
2. You should see three shop applications:
   - shop-dev
   - shop-staging
   - shop-prod
3. Each has labels showing the environment
4. Click on each to see the full microservices stack deployed

**Also verify via kubectl:**
```bash
# Check ApplicationSet
kubectl get applicationset -n argocd

# Check generated Applications  
kubectl get applications -n argocd | grep shop-
```

### 2.6 View in UI

1. Open Argo CD UI
2. You should see three shop applications
3. Each deploys the full microservices stack to a different namespace
4. Notice the environment labels

### 2.7 Monitor Deployments

**Note:** Deploying 3 full instances of the microservices demo (33 services total) takes time and resources. For the workshop, we'll monitor the progress:

```bash
# Watch all three environments
watch 'kubectl get pods -n shop-dev --no-headers | wc -l && kubectl get pods -n shop-staging --no-headers | wc -l && kubectl get pods -n shop-prod --no-headers | wc -l'
```

Or check each environment:

```bash
echo "=== Dev Environment ==="
kubectl get pods -n shop-dev

echo -e "\n=== Staging Environment ==="
kubectl get pods -n shop-staging

echo -e "\n=== Prod Environment ==="
kubectl get pods -n shop-prod
```

**Expected:** Each environment will have 11 microservices running.

### 2.8 Verify Environment Configuration

Each environment has the same microservices deployed:

```bash
echo "Dev environment:"
kubectl get deployments -n shop-dev

echo -e "\nStaging environment:"
kubectl get deployments -n shop-staging

echo -e "\nProd environment:"
kubectl get deployments -n shop-prod
```

**This demonstrates how ApplicationSets can deploy the same application to multiple environments!**

---

## Step 3: Git Directory Generator (Quick Example)

### 3.1 Understanding Git Generator

The Git generator automatically creates Applications based on directories in a Git repository.

**Use case:** Monorepo with multiple microservices, each in its own directory.

**For this step, we'll use a lightweight example to demonstrate the concept without overwhelming resources.**

### 3.2 Create Git Directory ApplicationSet

Create `appset-git-directories.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: demo-apps-auto
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/argoproj/argocd-example-apps.git
      revision: HEAD
      directories:
      - path: 'guestbook'
      - path: 'helm-guestbook'
  
  template:
    metadata:
      name: 'auto-{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'auto-{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

**Note:** We're using a filtered list of directories to avoid creating too many applications.

### 3.3 Apply Git Directory ApplicationSet

```bash
kubectl apply -f appset-git-directories.yaml
```

### 3.4 View Generated Applications via UI

In the UI:
1. Go to **Applications**
2. Look for applications with names starting with `auto-`:
   - auto-guestbook
   - auto-helm-guestbook
3. Click on them to see they were automatically created from Git directories

**Also check via kubectl:**
```bash
kubectl get applications -n argocd | grep auto-
```

### 3.5 Clean Up (Optional)

If you want to remove these demo apps:

```bash
kubectl delete applicationset demo-apps-auto -n argocd
```

---

## Step 4: Template Customization Examples

### 5.1 Using Parameters in Templates

ApplicationSets support various template parameters to customize deployments per environment.

### 5.2 Environment-Specific Configuration Example

Here's how you could customize different aspects per environment using parameters:

**Example with labels and annotations:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: customized-apps
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: dev
        namespace: app-dev
        resources: "small"
        monitoring: "false"
      - env: staging
        namespace: app-staging
        resources: "medium"
        monitoring: "true"
      - env: prod
        namespace: app-prod
        resources: "large"
        monitoring: "true"
  
  template:
    metadata:
      name: 'myapp-{{env}}'
      labels:
        environment: '{{env}}'
        resources: '{{resources}}'
      annotations:
        monitoring-enabled: '{{monitoring}}'
        managed-by: applicationset
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: guestbook
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

**Key customizations:**
- **Dev:** Small resources, no monitoring
- **Staging:** Medium resources, monitoring enabled  
- **Prod:** Large resources, monitoring enabled

### 5.3 Using Kustomize Replicas Override

If you need to set different replica counts per environment, use Kustomize:

```yaml
template:
  spec:
    source:
      path: guestbook
      kustomize:
        replicas:
        - name: guestbook-ui
          count: '{{replicas}}'
```

Then in your generators, add:
```yaml
- env: dev
  replicas: "1"
- env: prod
  replicas: "3"
```

---

## Step 5: Cluster Generator (Conceptual)

### 6.1 Understanding Cluster Generator

The Cluster generator creates Applications for each cluster registered in Argo CD.

**Use case:** Deploy the same application to multiple Kubernetes clusters.

### 6.2 List Registered Clusters

```bash
argocd cluster list
```

You should see:
- `https://kubernetes.default.svc` (in-cluster)

### 6.3 Cluster ApplicationSet Example

For reference, here's how a cluster generator works:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook-all-clusters
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          env: production
  
  template:
    metadata:
      name: '{{name}}-guestbook'
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: guestbook
      destination:
        server: '{{server}}'
        namespace: guestbook
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

**Note:** This is for reference. In this workshop, we only have one cluster.

---

## Step 6: Real-World ApplicationSet Best Practices

### 7.1 Naming Conventions

Use clear, consistent naming:

```yaml
template:
  metadata:
    name: '{{project}}-{{app}}-{{env}}'
```

### 7.2 Labels for Organization

```yaml
template:
  metadata:
    labels:
      managed-by: applicationset
      environment: '{{env}}'
      team: '{{team}}'
      app: '{{app}}'
```

### 7.3 Selective Sync Policies

Different sync policies per environment:

```yaml
generators:
- list:
    elements:
    - env: dev
      autoSync: "true"
    - env: prod
      autoSync: "false"

template:
  spec:
    syncPolicy:
      automated:
        prune: '{{autoSync}}'
        selfHeal: '{{autoSync}}'
```

---

## Exercises

Try these challenges:

### Exercise 1: Add a New Environment

Modify the `microservices-environments` ApplicationSet to add a new environment:

```bash
kubectl edit applicationset microservices-environments -n argocd
```

Add this to the list of elements:
```yaml
- environment: qa
  namespace: shop-qa
```

Save and verify a new Application appears in the UI automatically.

### Exercise 2: Create Custom Labels

Create an ApplicationSet with custom labels per environment:

```yaml
generators:
- list:
    elements:
    - env: dev
      team: "platform"
      tier: "development"
    - env: prod
      team: "sre"
      tier: "production"
```

Use these in the template metadata labels.

### Exercise 3: Git Directory Generator

Create an ApplicationSet using Git directory generator to automatically deploy all apps in specific paths:

```yaml
generators:
- git:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    revision: HEAD
    directories:
    - path: 'helm-*'
```

### Exercise 4: Matrix for Multi-Region Deployment

Design (don't deploy) a Matrix generator that would deploy apps to:
- 2 apps (frontend, backend)
- 3 environments (dev, staging, prod)  
- 2 clusters (us-east, eu-west)

Calculate: How many Applications would be created?
Answer: 2 × 3 × 2 = 12 Applications from one ApplicationSet!

---

## Verification Checklist

- [ ] Can create ApplicationSet with List generator
- [ ] Multiple Applications generated automatically
- [ ] Can use Git directory generator
- [ ] Can use Matrix generator
- [ ] Understand template parameters
- [ ] Can customize sync policies per environment
- [ ] Applications update when ApplicationSet changes

---

## Troubleshooting

### Problem: ApplicationSet created but no Applications

**Solution:** Check ApplicationSet status:
```bash
kubectl describe applicationset <name> -n argocd
```

Look for errors in the status section.

### Problem: Generated Applications have wrong names

**Solution:** Check template parameters:
```bash
kubectl get applicationset <name> -n argocd -o yaml
```

Verify the template name field uses correct parameter substitution.

### Problem: Too many Applications created

**Solution:** Delete the ApplicationSet:
```bash
kubectl delete applicationset <name> -n argocd
```

This will delete all generated Applications.

### Problem: Applications not updating

**Solution:** Check ApplicationSet generation:
```bash
kubectl get applicationset <name> -n argocd -o jsonpath='{.status.conditions}'
```

---

## Clean Up

### Remove Specific ApplicationSets

```bash
# Remove microservices environments
kubectl delete applicationset microservices-environments -n argocd

# Remove other examples if created
kubectl delete applicationset demo-apps-auto -n argocd
```

### Clean Up Namespaces

```bash
# Shop environments
kubectl delete namespace shop-dev shop-staging shop-prod

# Auto-generated (if you created the git directory example)
kubectl delete namespace auto-guestbook auto-helm-guestbook
```

**Note:** Deleting an ApplicationSet automatically deletes all Applications it generated, which in turn deletes all Kubernetes resources.

---

## What's Next?

Proceed to:
- **[Lab 5: App of Apps Pattern](../lab-05-app-of-apps/README.md)**
- **[Bonus Lab 1: Prometheus Metrics](../bonus-lab-01-prometheus/README.md)**
- **[Bonus Lab 2: Argo Rollouts - Blue/Green Deployments](../bonus-lab-02-rollouts/README.md)**

---

## Key Takeaways

✅ ApplicationSets automate Application creation at scale  
✅ List generator deploys to multiple environments with different configs  
✅ **Microservices demo shows real-world multi-environment deployment**  
✅ Git generator enables monorepo patterns  
✅ Matrix generator combines multiple dimensions (apps × envs × clusters)  
✅ **Helm values can be parameterized per environment**  
✅ Templates provide powerful parameterization  
✅ ApplicationSets reduce manual Application management by 90%  
✅ **Perfect for deploying production workloads to multiple environments**  
✅ One ApplicationSet can manage dozens of Applications

### Real-World Impact

**Without ApplicationSets:**
- 3 environments × 1 app = 3 manual Application manifests
- Any change requires updating 3 files
- Easy to make mistakes or forget an environment

**With ApplicationSets:**
- 1 ApplicationSet manifest
- Changes propagate automatically to all environments
- Environment-specific customization via parameters
- Scales to 10, 100, or 1000 applications

**For microservices demo:**
- One ApplicationSet deploys 11 services to 3 environments = 33 services
- All managed from one YAML file
- Environment-specific configurations (replicas, resources, features)
- Production-ready pattern!

---

## Additional Resources

- [ApplicationSet Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Generator Types](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators/)
- [Template Fields](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Template/)
- [ApplicationSet Examples](https://github.com/argoproj/argo-cd/tree/master/applicationset/examples)
