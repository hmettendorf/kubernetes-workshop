# Lab 2: Your First Application - Microservices Demo

## Overview

Deploy Google Cloud's microservices demo application using Argo CD. This is a realistic example of a multi-service application with frontend, backend services, and dependencies.

**Duration:** 75 minutes

**Learning Objectives:**
- Create an Argo CD Application resource
- Connect to Git repositories
- Deploy a complex microservices application
- Perform sync operations via the UI
- Monitor application health and sync status
- Use the Argo CD UI effectively
- Understand multi-service deployments

---

## Prerequisites

- Completed Lab 1 (Argo CD installed)
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

### 2.2 View Application in the UI

1. Open the Argo CD UI: `https://localhost:8080`
2. You should see the **microservices-demo** application appear in the applications list
3. Click on the application to view details

The application should show:
- **STATUS: OutOfSync** - Git state differs from cluster state
- **HEALTH: Missing** - Resources don't exist in cluster yet
- No auto-sync enabled - Manual sync required

---

## Step 3: Sync the Application via UI

### 3.1 Manual Sync using the Web UI

To deploy all microservices via the UI:

1. Click on the **microservices-demo** application
2. Click the **SYNC** button at the top
3. A sync options dialog will appear:
   - Review the resources that will be synced
   - Keep default options selected
   - Click **SYNCHRONIZE**

You'll see:
- The sync operation start
- Multiple resources being created in real-time
- Deployments rolling out
- Health status changing from Missing → Progressing → Healthy

**Note:** This may take 2-5 minutes as all container images are pulled.

### 3.2 Monitor Deployment Progress in UI

Watch the deployment in real-time within the Argo CD UI:

1. The application view shows a live graph of all services
2. Watch pods appear and turn from gray → blue → green
3. Click on individual deployments to see pod status
4. Use the **Events** tab to see detailed deployment events

**In a terminal**, you can also watch:
```bash
# Watch pods being created
kubectl get pods -n microservices-demo -w
```

### 3.3 Verify Deployment

In the Argo CD UI:
- Application tile should show **Synced** and **Healthy** (once all pods are running)
- The graph view shows all 11 microservices in green

Verify all resources in Kubernetes:

```bash
# View all resources
kubectl get all -n microservices-demo

# Check individual deployments
kubectl get deployments -n microservices-demo

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

**Note:** If you patched the service NodePort in Step 5, that patch also created drift! You can check in the UI.

### 7.2 Check Drift in Argo CD UI

View the application in Argo CD:

1. Open the **microservices-demo** application in the UI
2. Notice the application status shows **OutOfSync**
3. The application tile turns yellow/orange
4. Argo CD detected the drift!

### 7.3 View the Diff in the UI

See exactly what changed:

1. In the application view, click the **APP DIFF** button at the top
2. This shows a side-by-side comparison of Git vs Live state
3. You'll see the replica count difference highlighted
4. Click on the **frontend** deployment in the resource tree to see specific changes

### 7.4 Sync to Revert via UI

Since Git is the source of truth, sync to revert our manual change:

1. Click the **SYNC** button
2. In the sync dialog, review the changes
3. Click **SYNCHRONIZE**

The frontend will scale back to 1 replica (as defined in Git).

You can verify:
```bash
kubectl get deployment frontend -n microservices-demo
# Should show 1/1 replicas
```

---

## Step 8: Create Application Declaratively

The GitOps way: define the Application as YAML (which you've already done!).

### 8.1 Review What You've Learned

You've already created the application declaratively in Step 2! The file `microservices-demo-app.yaml` is the declarative definition.

If you needed to delete and recreate:

```bash
# Delete via kubectl
kubectl delete application microservices-demo -n argocd
```

**Or via UI:**
1. Go to Applications
2. Click the three dots ⋮ on the application
3. Select **Delete**
4. Confirm deletion

### 8.2 Recreate via UI (Alternative Method)

Instead of using `kubectl apply`, you can also create applications directly in the UI:

1. Click **+ NEW APP** button
2. Fill in the form:
   - **Application Name**: microservices-demo
   - **Project**: default
   - **Sync Policy**: Manual
   - **Repository URL**: https://github.com/GoogleCloudPlatform/microservices-demo.git
   - **Revision**: HEAD
   - **Path**: helm-chart
   - **Cluster URL**: https://kubernetes.default.svc
   - **Namespace**: microservices-demo
3. Click **CREATE**

### 8.3 Configure Helm Values via UI

When creating via UI, you can also add Helm values:

1. Scroll down to **HELM** section
2. Click **VALUES FILES** or **PARAMETERS**
3. Add custom values as needed

### 8.4 Verify Creation

In the UI:
- The new application appears in the applications list
- Click on it to view details
- Sync it using the **SYNC** button

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

### Exercise 1: Enable Auto-Sync via UI

Modify the application to use automated sync with self-healing using the UI:

1. Click on the **microservices-demo** application
2. Click **APP DETAILS** button
3. Scroll to **SYNC POLICY** section
4. Click **ENABLE AUTO-SYNC**
5. Check **PRUNE RESOURCES** and **SELF HEAL**
6. Click **OK**

Test by manually scaling a deployment - it should auto-revert!

### Exercise 2: View Application Logs via UI

Use Argo CD UI to view logs from different services:

1. Click on the **microservices-demo** application
2. Click on a pod in the resource tree (e.g., frontend)
3. Click the **LOGS** tab
4. View real-time logs
5. Try different pods to compare logs

### Exercise 3: Explore Resource Details via UI

In the UI, explore:
1. Click on different resources in the tree view
2. View the **SUMMARY** tab for resource information
3. Check the **EVENTS** tab for Kubernetes events
4. Use the **MANIFEST** tab to see the full YAML
5. Explore service endpoints and pod details

### Exercise 4: Simulate Service Failure

Delete a pod and watch Kubernetes and Argo CD recover it:

```bash
kubectl delete pod -n microservices-demo -l app=frontend
```

Watch in the UI:
1. The pod disappears from the tree
2. Kubernetes creates a new one automatically
3. Watch it progress through ContainerCreating → Running
4. Argo CD shows the recovery in real-time

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

**Solution:** Refresh and check differences in the UI:
1. Click on the application
2. Click **REFRESH** button (circular arrow icon)
3. Click **APP DIFF** to see what's different
4. Sync if needed using the **SYNC** button

---

## Clean Up

### Option 1: Keep for Next Lab

Keep the application running for Lab 3 (Drift Detection).

### Option 2: Delete Application via UI

1. Go to the Applications view
2. Click the three dots ⋮ on the microservices-demo application
3. Select **Delete**
4. In the dialog, check **Cascade** to delete all resources
5. Confirm deletion

### Option 3: Delete via kubectl

```bash
# Delete the application (this removes all deployed resources)
kubectl delete application microservices-demo -n argocd
```

### Option 4: Delete Only App Resources

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
✅ Sync operations via UI deploy complete application stacks from Git  
✅ The UI provides comprehensive visibility and control  
✅ The UI visual graph helps understand service dependencies  
✅ Drift detection works across all application resources  
✅ Declarative application definitions enable complete GitOps  
✅ The web interface makes GitOps accessible without CLI knowledge

---

## Additional Resources

- [Microservices Demo GitHub](https://github.com/GoogleCloudPlatform/microservices-demo)
- [Application Architecture Diagram](https://github.com/GoogleCloudPlatform/microservices-demo#architecture)
- [Service Details](https://github.com/GoogleCloudPlatform/microservices-demo#service-architecture)
