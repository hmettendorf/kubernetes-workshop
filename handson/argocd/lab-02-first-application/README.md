# Lab 2: Your First Application - Microservices Demo

## Overview

Deploy Google Cloud's microservices demo application using Argo CD. This is a realistic example of a multi-service application with frontend, backend services, and dependencies.

**Duration:** 75 minutes

**Learning Objectives:**
- Create an Argo CD Application resource
- Connect to Git repositories
- Deploy a complex microservices application
- Perform manual sync operations
- Monitor application health and sync status
- Use the Argo CD UI and CLI
- Understand multi-service deployments

---

## Prerequisites

- Completed Lab 1 (Argo CD installed)
- Argo CD CLI logged in
- Access to the Argo CD UI
- Rancher Desktop with k3s running

---

## About the Microservices Demo

The **Google Cloud microservices demo** (formerly known as "Online Boutique") is a cloud-native microservices demo application consisting of 11 microservices:

- **Frontend** - Exposes an HTTP server to serve the website
- **Cart Service** - Stores items in the user's shopping cart
- **Product Catalog Service** - Provides the list of products
- **Currency Service** - Converts currencies
- **Payment Service** - Charges the user's credit card
- **Shipping Service** - Gives shipping cost estimates
- **Email Service** - Sends order confirmation emails
- **Checkout Service** - Retrieves cart, prepares order, orchestrates payment and shipping
- **Recommendation Service** - Recommends other products
- **Ad Service** - Provides advertisement
- **Load Generator** - Continuously sends requests to the frontend

Repository: https://github.com/GoogleCloudPlatform/microservices-demo

---

## Step 1: Add Application to Your Git Repository

### 1.1 Copy Application Manifest to Your Branch

Navigate to your seeds repository and copy the lab manifest:

```bash
# Go to your seeds repository
cd ~/kubernetes-workshop-seeds

# Verify you're on your branch
git branch

# Copy the application manifest
cp ~/kubernetes-workshop/handson/argocd/lab-02-first-application/microservices-demo-app.yaml .
```

**Note:** Since each participant has their own Kubernetes cluster, there's no need to customize names or namespaces. The default values will work fine!

### 1.2 Review the Manifest

Let's quickly review what we're deploying:

```bash
cat microservices-demo-app.yaml
```

The Application manifest tells ArgoCD:
- **Where** to find the source (GitHub repository with Helm chart)
- **What** namespace to deploy to
- **How** to sync (automatic or manual)

### 1.3 Commit and Push to Git

```bash
# Add the file
git add microservices-demo-app.yaml

# Commit with a meaningful message
git commit -m "Lab 2: Add microservices demo application"

# Push to your branch
git push
```

**This is GitOps!** Your Git repository is now the source of truth for this application.

---

## Step 2: Deploy Application with Argo CD

### 2.1 Apply the Application Resource

Now tell Argo CD to manage this application:

```bash
# Apply the Application resource to the cluster
kubectl apply -f microservices-demo-app.yaml
```

### 2.2 View Application Status

```bash
# View in CLI
argocd app list

# Get detailed info
argocd app get microservices-demo
```

Output should show:
```
NAME                 CLUSTER                         NAMESPACE          PROJECT  STATUS     HEALTH   SYNCPOLICY  CONDITIONS
microservices-demo   https://kubernetes.default.svc  microservices-demo default  OutOfSync  Missing  <none>      <none>
```

Notice:
- **STATUS: OutOfSync** - Git state differs from cluster state
- **HEALTH: Missing** - Resources don't exist in cluster yet
- **No syncPolicy** - Manual sync required

---

## Step 3: Sync the Application

### 3.1 Manual Sync via CLI

Sync the application to deploy all microservices:

```bash
argocd app sync microservices-demo
```

Watch the sync progress. You'll see:
- Multiple resources being created
- Deployments rolling out
- Services being exposed
- Health status changing from Missing → Progressing → Healthy

**Note:** This may take 2-5 minutes as all container images are pulled.

### 3.2 Monitor Deployment Progress

Watch the deployment in real-time:

```bash
# Watch pods being created
kubectl get pods -n microservices-demo -w

# In another terminal, check deployment status
kubectl get deployments -n microservices-demo
```

### 3.3 Verify Deployment

Check the application status:

```bash
argocd app get microservices-demo
```

You should eventually see:
- **STATUS: Synced**
- **HEALTH: Healthy** (once all pods are running)

Verify all resources in Kubernetes:

```bash
# View all resources
kubectl get all -n microservices-demo

# Check individual deployments
kubectl get deployments -n microservices-demo

# Check services
kubectl get services -n microservices-demo

# Verify all pods are running
kubectl get pods -n microservices-demo
```

You should see 11 deployments and their corresponding pods.

---

## Step 4: Explore the Argo CD UI

### 4.1 View Application in UI

1. Open the Argo CD UI: `https://localhost:8080`
2. Click on the **microservices-demo** application

### 4.2 Explore Application View

The UI shows:
- **Top bar** - Sync status, health, repo info
- **Graph view** - Visual representation of all microservices
- **Resource tree** - Hierarchical view showing all deployments, services, pods
- **Details panel** - Resource-specific information

You'll see a complex graph with all 11 microservices and their relationships!

### 4.3 Navigate the Resource Tree

Click on different resources to see:
- YAML definitions for each service
- Events for deployments
- Logs for pods
- Service endpoints
- Resource dependencies

Try exploring:
- **frontend** deployment
- **productcatalog** service
- Any pod to view logs

---

## Step 5: Access the Application

### 5.1 Check Frontend Service

The frontend service is created with a LoadBalancer type:

```bash
kubectl get service frontend-external -n microservices-demo
```

On k3s (Rancher Desktop), the LoadBalancer will get an external IP automatically via the built-in ServiceLB.

### 5.2 Access via Port-Forward (Recommended)

The most reliable way to access the application on Rancher Desktop is via port-forwarding:

```bash
kubectl port-forward -n microservices-demo svc/frontend-external 8080:80
```

Keep this terminal open. The port-forward will run until you stop it (Ctrl+C).

### 5.3 Open in Browser

Open your browser to: `http://localhost:8080`

You should see the **Online Boutique** web application with:
- Product catalog
- Shopping cart functionality
- Checkout process
- Currency selection

**Alternative - NodePort Access:**

If you prefer to use NodePort, the LoadBalancer service automatically gets a NodePort assigned:

```bash
# Find the NodePort
kubectl get svc frontend-external -n microservices-demo -o jsonpath='{.spec.ports[0].nodePort}'
```

Then access via: `http://localhost:<nodeport>`

**Note:** With Rancher Desktop's k3s, port-forwarding is the most reliable method for local access.

**Alternative - Port Forward Method:**

If you prefer using port forwarding instead of NodePort:

```bash
kubectl port-forward -n microservices-demo svc/frontend-external 8081:80
```

Then access at: `http://localhost:8081`

**Tip:** Leave port-forward running in a separate terminal while you explore other steps.

---

## Step 6: Explore Application Behavior

### 6.1 View Service Communication

Check logs to see inter-service communication:

```bash
# Frontend logs
kubectl logs -n microservices-demo -l app=frontend --tail=50

# Recommendation service logs
kubectl logs -n microservices-demo -l app=recommendationservice --tail=50
```

### 6.2 View Load Generator

The load generator continuously hits the frontend:

```bash
kubectl logs -n microservices-demo -l app=loadgenerator --tail=20 -f
```

You'll see simulated user traffic!

---

## Step 7: Make Changes and Observe

### 7.1 Scale a Service

Let's scale the frontend deployment:

```bash
# Scale frontend to 3 replicas
kubectl scale deployment frontend -n microservices-demo --replicas=3
```

**Note:** If you patched the service NodePort in Step 5, that patch also created drift! You can check:

```bash
# Check if application shows OutOfSync
argocd app get microservices-demo
```

The service patch won't be detected unless you refresh the application or wait for the reconciliation cycle.

### 7.2 Check Drift in Argo CD

View the application in Argo CD:

```bash
argocd app get microservices-demo
```

Notice:
- **STATUS: OutOfSync** - Because we manually changed replicas
- Argo CD detected the drift!

### 7.3 View the Diff

See exactly what changed:

```bash
argocd app diff microservices-demo
```

**In the UI:**
1. The application shows "OutOfSync"
2. Click on the frontend deployment
3. View the diff showing the replica change

### 7.4 Sync to Revert

Since Git is the source of truth, sync to revert our manual change:

```bash
argocd app sync microservices-demo
```

The frontend will scale back to 1 replica (as defined in Git).

---

## Step 8: Create Application Declaratively

The GitOps way: define the Application as YAML.

### 8.1 Delete Current Application

```bash
argocd app delete microservices-demo
```

Confirm with `y`.

### 8.2 Create Application Manifest

Create `microservices-demo-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-demo
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/GoogleCloudPlatform/microservices-demo.git
    targetRevision: HEAD
    path: helm-chart
    helm:
      values: |
        serviceAccounts:
          create: true
        networkPolicies:
          create: false
        sidecars:
          create: false
        frontend:
          externalService: true
  
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices-demo
  
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
    - CreateNamespace=true
```

**Key changes from previous version:**
- Using `helm-chart` path instead of `release`
- Added `helm.values` to disable Istio features
- Disables NetworkPolicies and sidecars (not needed without service mesh)
- Enables external service (LoadBalancer type)

**Note:** The LoadBalancer service will get a random NodePort. After deployment, you can patch it to use a specific port (see Step 5) or use port-forwarding for access.

### 8.3 Apply the Application

```bash
kubectl apply -f microservices-demo-app.yaml
```

### 8.4 Verify Creation

```bash
argocd app list
kubectl get applications -n argocd
```

### 8.5 Sync the Application

```bash
argocd app sync microservices-demo
```

---

## Step 9: Understand the Application Structure

### 9.1 Examine Deployed Resources

```bash
# Count resources
kubectl get all -n microservices-demo | wc -l

# View deployments with images
kubectl get deployments -n microservices-demo -o wide

# View services and their types
kubectl get services -n microservices-demo
```

### 9.2 Understand Service Architecture

The services communicate using Kubernetes DNS:
- `frontend` calls `productcatalogservice`
- `frontend` calls `currencyservice`
- `checkoutservice` orchestrates multiple backend services

View environment variables showing service dependencies:

```bash
kubectl describe deployment frontend -n microservices-demo | grep -A 20 "Environment:"
```

---

## Exercises

Try these challenges:

### Exercise 1: Enable Auto-Sync

Modify the application to use automated sync with self-healing:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
  - CreateNamespace=true
```

Apply and test by manually scaling a deployment.

### Exercise 2: View Application Logs

Use Argo CD CLI to view logs from different services:

```bash
argocd app logs microservices-demo --kind Deployment --name frontend
argocd app logs microservices-demo --kind Deployment --name cartservice
```

### Exercise 3: Explore Resource Details

In the UI, explore:
- Pod resource usage
- Service endpoints
- ConfigMaps (if any)
- Deployment strategies

### Exercise 4: Simulate Service Failure

Delete a pod and watch Kubernetes and Argo CD recover it:

```bash
kubectl delete pod -n microservices-demo -l app=frontend
```

Watch in the UI how it's recreated.

---

## Verification Checklist

- [ ] Application created successfully
- [ ] All 11 microservices deployed
- [ ] Application synced and healthy
- [ ] Can access the web UI via port-forward
- [ ] Can view all services in Argo CD UI
- [ ] Can view logs for individual services
- [ ] Understand drift detection
- [ ] Created application declaratively
- [ ] Explored service dependencies

---

## Troubleshooting

### Problem: Pods stuck in Pending state

**Solution:** Check resources:
```bash
kubectl describe pod <pod-name> -n microservices-demo
```

May need to increase Rancher Desktop memory allocation.

### Problem: Images not pulling

**Solution:** Check image pull status:
```bash
kubectl get pods -n microservices-demo
kubectl describe pod <pod-name> -n microservices-demo | grep -A 10 Events
```

### Problem: Frontend not accessible

**Solution:** Verify service and port-forward:
```bash
kubectl get svc frontend-external -n microservices-demo
# Ensure port-forward is running on correct port
kubectl port-forward -n microservices-demo svc/frontend-external 8081:80
```

### Problem: Application OutOfSync

**Solution:** Refresh and check differences:
```bash
argocd app get microservices-demo --refresh
argocd app diff microservices-demo
```

---

## Clean Up

### Option 1: Keep for Next Lab

Keep the application running for Lab 3 (Drift Detection).

### Option 2: Delete Application

```bash
argocd app delete microservices-demo
```

This will remove all deployed resources.

### Option 3: Delete Only App Resources

```bash
# Delete namespace and all resources
kubectl delete namespace microservices-demo
```

---

## What's Next?

Proceed to:
- **[Lab 3: Drift Detection & Self-Healing](../lab-03-drift-detection/README.md)** - We'll use this same application to experiment with drift detection and self-healing!

---

## Key Takeaways

✅ Argo CD can manage complex multi-service applications  
✅ Applications connect Git repos to Kubernetes clusters  
✅ Sync operations deploy complete application stacks from Git  
✅ Both CLI and UI provide comprehensive visibility  
✅ The UI visual graph helps understand service dependencies  
✅ Drift detection works across all application resources  
✅ Declarative application definitions enable complete GitOps

---

## Additional Resources

- [Microservices Demo GitHub](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Application Architecture Diagram](https://github.com/GoogleCloudPlatform/microservices-demo#architecture)
- [Service Details](https://github.com/GoogleCloudPlatform/microservices-demo#service-architecture)
