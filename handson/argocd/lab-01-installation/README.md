# Lab 1: Argo CD Installation & Setup

## Overview

In this lab, you'll install Argo CD on Rancher Desktop with k3s and configure access to both the UI and CLI.

**Duration:** 60 minutes

**Learning Objectives:**
- Install Argo CD on k3s using kubectl
- Access the Argo CD web UI
- Understand Argo CD architecture components
- Navigate the Argo CD web interface

---

## Prerequisites

- Rancher Desktop installed with k3s running
- `kubectl` installed and configured
- Port-forwarding capability (for UI access)
- Internet access for downloading images
- Web browser

### Verify Rancher Desktop Setup

Before starting, verify your environment:

```bash
# Check kubectl is configured
kubectl version --short

# Verify k3s cluster is running
kubectl get nodes

# Check available resources
kubectl top nodes  # Optional, requires metrics-server
```

You should see your k3s node in Ready state.

---

## Step 1: Install Argo CD

### 1.1 Create Namespace

First, create a dedicated namespace for Argo CD:

```bash
kubectl create namespace argocd
```

### 1.2 Install Argo CD via Helm (Recommended)

**Using Helm provides better CRD management and easier customization.**

```bash
helm install my-argo-cd oci://ghcr.io/argoproj/argo-helm/argo-cd --version 9.4.15 -n argocd
```

**Alternative: Install via kubectl manifests:**

If you prefer the traditional method:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Note:** The Helm method is recommended as it properly handles CRDs and provides better configuration options.

This installs:
- `argocd-server` - API server and UI
- `argocd-repo-server` - Repository service
- `argocd-application-controller` - Application controller
- `argocd-applicationset-controller` - ApplicationSet controller
- `argocd-redis` - Cache
- `argocd-dex-server` - Identity provider integration
- `argocd-notifications-controller` - Notification service

**Note:** The installation may take 2-3 minutes as container images are pulled.

### 1.3 Verify Installation

Wait for all pods to be running:

```bash
kubectl get pods -n argocd
```

Expected output (all pods should be `Running`):
```
NAME                                  READY   STATUS    RESTARTS   AGE
argocd-application-controller-0       1/1     Running   0          1m
argocd-dex-server-xxx                 1/1     Running   0          1m
argocd-redis-xxx                      1/1     Running   0          1m
argocd-repo-server-xxx                1/1     Running   0          1m
argocd-server-xxx                     1/1     Running   0          1m
```

You can also check the services:

```bash
kubectl get svc -n argocd
```

---

## Step 2: Access the Argo CD UI

### 2.1 Expose the UI

For local development, use port-forwarding:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

> **Note:** Keep this terminal open. The port-forward will run until you terminate it (Ctrl+C).

### 2.2 Get Initial Admin Password

Argo CD generates an initial admin password during installation:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Save this password!** You'll need it to log in.

### 2.3 Access the UI

Open your browser and navigate to:
```
https://localhost:8080
```

> **Note:** You'll see a certificate warning because Argo CD uses a self-signed certificate. This is safe for local development - click "Advanced" and proceed.

**Login credentials:**
- Username: `admin`
- Password: (the password from step 2.2)

### 2.4 Explore the UI

Take a moment to explore:
- **Applications** - List of deployed applications (currently empty)
- **Settings** - Configuration options
- **User Info** - Account details

---

## Step 3: Explore the Argo CD UI

### 3.1 Navigate Applications View

In the Argo CD UI:
1. Click on **Applications** in the left sidebar
2. This shows all deployed applications (currently empty)
3. You can filter, sort, and search applications here

### 3.2 Explore Settings

1. Click on **Settings** (gear icon) in the left sidebar
2. Explore the available options:
   - **Repositories** - Git repositories Argo CD can access
   - **Clusters** - Kubernetes clusters Argo CD can deploy to
   - **Projects** - Logical grouping of applications
   - **Accounts** - User accounts and permissions

### 3.3 View Cluster Information

1. Go to **Settings** → **Clusters**
2. You should see the `in-cluster` entry (where Argo CD is installed)
3. Click on it to see cluster details and connection status

---

## Step 4: Change Admin Password (Optional but Recommended)

For security, change the default admin password via the UI:

1. Click on **User Info** (person icon) in the left sidebar
2. Click on **Update Password**
3. Enter the current password (from Step 2.2)
4. Enter and confirm a new password
5. Click **Save**

**Alternative: Change password via kubectl**
```bash
# Get current password first
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Then update in UI as described above
```

---

## Step 5: Explore Argo CD Components

### 6.1 View Argo CD Resources

```bash
# View all resources in argocd namespace
kubectl get all -n argocd

# View ConfigMaps
kubectl get configmap -n argocd

# View Secrets
kubectl get secrets -n argocd
```

### 6.2 Check Argo CD Version

```bash
argocd version
```

### 5.2 Check Argo CD Version

In the UI:
1. Click on **User Info** (person icon) → **About**
2. You'll see the server version information

**Or via kubectl:**

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].spec.containers[0].image}'
```

---

## Step 6: Configure Cluster (if using external cluster)

If you want Argo CD to manage applications on external clusters, you can add them via the UI:

### 6.1 Add External Cluster via UI

1. Go to **Settings** → **Clusters**
2. Click **+ Connect Cluster**
3. Select the cluster from your kubeconfig or enter connection details
4. Configure permissions and click **Create**

> **Note:** For this workshop, we'll use the in-cluster context (where Argo CD is installed).

**Alternative: Add via kubectl**
```bash
# List available contexts
kubectl config get-contexts

# Create a service account and get credentials
# Then add via the UI using the Settings → Clusters interface
```

---

## Verification

Verify everything is working:

1. **UI Access**: Navigate to `https://localhost:8080` and ensure you can log in
2. **Applications View**: Verify the Applications page loads (should be empty)
3. **Settings Access**: Check that you can access Settings and see the in-cluster

**Via kubectl:**
```bash
# Check UI access
curl -k https://localhost:8080/healthz
```

Expected: `ok`

---

## Clean Up (Don't run this yet!)

When you're done with all labs, you can remove Argo CD:

```bash
kubectl delete namespace argocd
```

---

## Troubleshooting

### Problem: Port-forward not working

**Solution:** Make sure no other service is using port 8080:
```bash
# Use a different port
kubectl port-forward svc/argocd-server -n argocd 9090:443
```

Then access at `https://localhost:9090`

### Problem: Cannot get admin password

**Solution:** The secret might not be created yet. Wait a minute and try again:
```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Problem: CLI login fails

**Solution:** Not applicable - we're using the web UI. If you need CLI access for debugging, make sure port-forward is running and use `--insecure` flag:
```bash
# This is for advanced users only
argocd login localhost:8080 --insecure
```

### Problem: Pods not starting

**Solution:** Check pod logs:
```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller
```

---

## What's Next?

Now that Argo CD is installed and configured, proceed to:
- **[Lab 2: Your First Application](../lab-02-first-application/README.md)** - Deploy your first app with Argo CD

---

## Additional Resources

- [Argo CD Installation Docs](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Argo CD Architecture](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/)
- [Argo CD UI Overview](https://argo-cd.readthedocs.io/en/stable/user-guide/)
