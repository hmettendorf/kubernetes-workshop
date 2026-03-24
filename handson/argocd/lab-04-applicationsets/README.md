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
- Different replica counts per environment (prod has 2 frontend replicas)
- Istio features disabled via Helm values
- Automatic sync enabled for all environments
- Each environment isolated in its own namespace
- Creates namespaces automatically

The ApplicationSet will generate 3 Applications:
- `shop-dev` → deploys to `shop-dev` namespace
- `shop-staging` → deploys to `shop-staging` namespace
- `shop-prod` → deploys to `shop-prod` namespace with 2 frontend replicas

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

### 2.5 Verify Applications Created

```bash
# Check ApplicationSet
kubectl get applicationset -n argocd

# Check generated Applications
argocd app list | grep shop-

# You should see:
# - shop-dev
# - shop-staging
# - shop-prod
```

1. Open Argo CD UI
2. You should see three shop applications
3. Each deploys the full microservices stack to a different namespace
4. Notice the environment labels

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

### 2.8 Verify Different Configurations

Check that prod has 2 frontend replicas while dev/staging have 1:

```bash
echo "Dev frontend replicas:"
kubectl get deployment frontend -n shop-dev -o jsonpath='{.spec.replicas}'

echo -e "\nStaging frontend replicas:"
kubectl get deployment frontend -n shop-staging -o jsonpath='{.spec.replicas}'

echo -e "\nProd frontend replicas:"
kubectl get deployment frontend -n shop-prod -o jsonpath='{.spec.replicas}'
```

**This demonstrates how ApplicationSets can deploy the same application with environment-specific configurations!**

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

### 3.4 View Generated Applications

```bash
argocd app list | grep auto-
```

This creates Applications for the specified directories:
- `auto-guestbook`
- `auto-helm-guestbook`

### 3.5 Clean Up (Optional)

If you want to remove these demo apps:

```bash
kubectl delete applicationset demo-apps-auto -n argocd
```

---

## Step 4: Matrix Generator - Real-World Example

### 4.1 Understanding Matrix Generator

The Matrix generator combines two generators to create a Cartesian product.

**Real-world example:** Deploy multiple versions of the microservices demo to multiple environments for A/B testing or blue/green deployments.

### 4.2 Create Matrix ApplicationSet

For this example, we'll deploy different configurations to different environments:

Create `appset-matrix-shop.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: matrix-shop-configs
  namespace: argocd
spec:
  generators:
  - matrix:
      generators:
      - list:
          elements:
          - config: standard
            replicas: "1"
          - config: performance
            replicas: "2"
      - list:
          elements:
          - env: dev
            namespace: matrix-dev
          - env: test
            namespace: matrix-test
  
  template:
    metadata:
      name: 'shop-{{config}}-{{env}}'
      labels:
        config: '{{config}}'
        environment: '{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/GoogleCloudPlatform/microservices-demo.git
        targetRevision: HEAD
        path: helm-chart
        helm:
          values: |
            networkPolicies:
              create: false
            sidecars:
              create: false
            frontend:
              replicas: {{replicas}}
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

### 4.3 Apply Matrix ApplicationSet

**Warning:** This creates 4 applications (2 configs × 2 environments), each deploying the full microservices stack. This is resource-intensive!

For the workshop, let's use a simpler example:

Create `appset-matrix-simple.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: matrix-apps-envs
  namespace: argocd
spec:
  generators:
  - matrix:
      generators:
      - list:
          elements:
          - app: guestbook
            path: guestbook
          - app: helm-guestbook
            path: helm-guestbook
      - list:
          elements:
          - env: dev
            namespace: dev
          - env: staging
            namespace: staging
  
  template:
    metadata:
      name: '{{app}}-{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: '{{path}}'
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

### 4.4 Apply Simple Matrix ApplicationSet

```bash
kubectl apply -f appset-matrix-simple.yaml
```

### 4.5 View Generated Applications

```bash
argocd app list
```

This creates:
- `guestbook-dev`
- `guestbook-staging`
- `helm-guestbook-dev`
- `helm-guestbook-staging`

**Result:** 2 apps × 2 environments = 4 Applications automatically created!

### 4.6 Real-World Matrix Use Case

**For production scenarios**, the Matrix generator with microservices demo would enable:

- **A/B Testing:** Deploy different versions to different user segments
- **Blue/Green:** Deploy old and new versions side-by-side
- **Performance Testing:** Deploy with different resource configurations
- **Multi-Region:** Deploy to multiple cloud regions or clusters

**Example pattern:**
```
2 versions × 3 environments × 2 regions = 12 Applications
All managed by one ApplicationSet!
```

---

## Step 5: Template Customization with Microservices Demo

### 5.1 Using Parameters in Templates

ApplicationSets support various template parameters to customize deployments per environment.

### 5.2 Advanced Templating - Environment-Specific Resources

Create `appset-advanced-microservices.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: advanced-shop
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: dev
        namespace: shop-dev
        frontendReplicas: "1"
        cartReplicas: "1"
        enableLoadGen: "true"
      - env: staging
        namespace: shop-staging
        frontendReplicas: "2"
        cartReplicas: "1"
        enableLoadGen: "true"
      - env: prod
        namespace: shop-prod
        frontendReplicas: "3"
        cartReplicas: "2"
        enableLoadGen: "false"
  
  template:
    metadata:
      name: 'shop-advanced-{{env}}'
      labels:
        environment: '{{env}}'
        managed-by: applicationset
      annotations:
        frontend-replicas: '{{frontendReplicas}}'
        cart-replicas: '{{cartReplicas}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/GoogleCloudPlatform/microservices-demo.git
        targetRevision: HEAD
        path: helm-chart
        helm:
          values: |
            networkPolicies:
              create: false
            sidecars:
              create: false
            frontend:
              replicas: {{frontendReplicas}}
            cartservice:
              replicas: {{cartReplicas}}
            loadgenerator:
              create: {{enableLoadGen}}
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
- **Dev:** Minimal resources, load generator enabled for testing
- **Staging:** Medium resources, load generator for performance testing
- **Prod:** High resources, no load generator (real traffic only)

### 5.3 Simpler Example for Workshop

For the workshop, let's use a lightweight version:

Create `appset-template-demo.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: template-demo
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: dev
        replicas: "1"
        resources: "small"
      - env: prod
        replicas: "3"
        resources: "large"
  
  template:
    metadata:
      name: 'app-{{env}}'
      annotations:
        replicas: '{{replicas}}'
        resources: '{{resources}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: guestbook
        kustomize:
          replicas:
          - name: guestbook-ui
            count: '{{replicas}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'app-{{env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

Apply:

```bash
kubectl apply -f appset-template-demo.yaml
```

### 5.4 Verify Different Configurations

```bash
# Check dev environment (should have 1 replica)
kubectl get deployment guestbook-ui -n app-dev -o jsonpath='{.spec.replicas}'

# Check prod environment (should have 3 replicas)
kubectl get deployment guestbook-ui -n app-prod -o jsonpath='{.spec.replicas}'
```

---

## Step 6: Cluster Generator (Conceptual)

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

## Step 7: Real-World ApplicationSet Best Practices

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

### Exercise 1: Create Multi-Environment Microservices ApplicationSet

Create an ApplicationSet that deploys the microservices demo to dev, qa, and prod with different configurations:

```yaml
generators:
- list:
    elements:
    - env: dev
      replicas: "1"
      loadGenerator: "true"
    - env: qa
      replicas: "2"
      loadGenerator: "true"
    - env: prod
      replicas: "3"
      loadGenerator: "false"
```

**Challenge:** Use Helm values to control:
- Frontend replica count
- Load generator enabled/disabled
- Cart service replica count

### Exercise 2: Modify Existing ApplicationSet

Update the `microservices-environments` ApplicationSet to add a new environment:
- Add `qa` environment with 1 replica
- Apply the change
- Verify a new Application is created automatically

```bash
kubectl edit applicationset microservices-environments -n argocd
# Add qa environment to the list
# Save and watch the new application appear
argocd app list | grep shop-
```

### Exercise 3: Resource Limits Per Environment

Create an ApplicationSet that sets different resource limits for each environment:

```yaml
- env: dev
  cpu: "100m"
  memory: "128Mi"
- env: prod
  cpu: "500m"
  memory: "512Mi"
```

Use Helm values to apply these limits to the frontend service.

### Exercise 4: Git Directory Generator with Filters

Explore the argocd-example-apps repository and create a filtered git directory generator:

```yaml
directories:
- path: 'helm-*'  # Only Helm-based apps
- path: 'kustomize-*'  # Only Kustomize-based apps
```

### Exercise 5: Matrix for Multi-Region Deployment

Design (don't deploy) a Matrix generator that would deploy microservices to:
- 2 versions (blue, green)
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

# Remove simple examples
kubectl delete applicationset matrix-apps-envs -n argocd
kubectl delete applicationset template-demo -n argocd
kubectl delete applicationset demo-apps-auto -n argocd
```

### Clean Up Namespaces

```bash
# Shop environments
kubectl delete namespace shop-dev shop-staging shop-prod

# Simple demo environments
kubectl delete namespace dev staging prod

# Matrix demo environments
kubectl delete namespace matrix-dev matrix-test

# Template demo
kubectl delete namespace app-dev app-prod

# Auto-generated
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
