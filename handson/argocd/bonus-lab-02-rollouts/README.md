# Bonus Lab 2: Argo Rollouts - Blue/Green Deployments

## Overview

Learn how to implement progressive delivery strategies with Argo Rollouts, including blue/green deployments and canary releases.

**Duration:** 60 minutes

**Learning Objectives:**
- Install and configure Argo Rollouts
- Implement blue/green deployment strategy
- Implement canary deployment strategy
- Perform automated analysis and rollback
- Integrate Rollouts with Argo CD
- Understand progressive delivery patterns

---

## Prerequisites

- Completed Labs 1-3
- Basic understanding of Kubernetes Services
- Understanding of deployment strategies

---

## What is Argo Rollouts?

**Argo Rollouts** is a Kubernetes controller that provides advanced deployment strategies:

- **Blue/Green Deployments** - Deploy new version alongside old, switch traffic atomically
- **Canary Deployments** - Gradually shift traffic to new version
- **Automated Analysis** - Validate deployments with metrics
- **Progressive Delivery** - Reduce risk of new releases

### Key Components

1. **Rollout** - Custom resource (CRD) that replaces Deployment
2. **AnalysisTemplate** - Defines metrics queries for automated validation
3. **Experiment** - Run parallel versions for testing

---

## Step 1: Install Argo Rollouts

### 1.1 Install Rollouts Controller

```bash
kubectl create namespace argo-rollouts

kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

### 1.2 Verify Installation

```bash
kubectl get pods -n argo-rollouts

# Should show:
# - argo-rollouts controller pod
```

### 1.3 Install Rollouts CLI

**macOS:**
```bash
brew install argoproj/tap/kubectl-argo-rollouts
```

**Linux:**
```bash
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

### 1.4 Verify CLI

```bash
kubectl argo rollouts version
```

---

## Step 2: Deploy First Rollout - Blue/Green Strategy

### 2.1 Create Demo Namespace

```bash
kubectl create namespace rollouts-demo
```

### 2.2 Create Blue/Green Rollout

Create `rollout-bluegreen.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-bluegreen-active
  namespace: rollouts-demo
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: rollout-bluegreen
---
apiVersion: v1
kind: Service
metadata:
  name: rollout-bluegreen-preview
  namespace: rollouts-demo
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: rollout-bluegreen
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-bluegreen
  namespace: rollouts-demo
spec:
  replicas: 2
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: rollout-bluegreen
  template:
    metadata:
      labels:
        app: rollout-bluegreen
    spec:
      containers:
      - name: rollouts-demo
        image: argoproj/rollouts-demo:blue
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        resources:
          requests:
            memory: 32Mi
            cpu: 5m
  strategy:
    blueGreen:
      activeService: rollout-bluegreen-active
      previewService: rollout-bluegreen-preview
      autoPromotionEnabled: false
```

### 2.3 Apply Rollout

```bash
kubectl apply -f rollout-bluegreen.yaml
```

### 2.4 Watch Rollout Status

```bash
kubectl argo rollouts get rollout rollout-bluegreen -n rollouts-demo --watch
```

You should see the rollout status with the current image (blue).

---

## Step 3: Perform Blue/Green Deployment

### 3.1 Access the Application

In a new terminal:

```bash
kubectl port-forward -n rollouts-demo svc/rollout-bluegreen-active 8080:80
```

Open `http://localhost:8080` - you should see a **blue** square.

### 3.2 Update to Green Version

Update the image to trigger a rollout:

```bash
kubectl argo rollouts set image rollout-bluegreen -n rollouts-demo \
  rollouts-demo=argoproj/rollouts-demo:green
```

### 3.3 Watch the Rollout

```bash
kubectl argo rollouts get rollout rollout-bluegreen -n rollouts-demo --watch
```

You'll see:
- New ReplicaSet created (green version)
- Preview service pointing to new version
- Rollout paused, waiting for promotion

### 3.4 Preview the New Version

In a new terminal:

```bash
kubectl port-forward -n rollouts-demo svc/rollout-bluegreen-preview 8081:80
```

Open `http://localhost:8081` - you should see a **green** square (new version).

The active service still shows **blue** (old version)!

### 3.5 Promote the Rollout

Once you've validated the green version:

```bash
kubectl argo rollouts promote rollout-bluegreen -n rollouts-demo
```

### 3.6 Verify Promotion

Check `http://localhost:8080` - it should now show **green**.

The traffic switched atomically from blue to green!

---

## Step 4: Implement Canary Deployment

### 4.1 Create Canary Rollout

Create `rollout-canary.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rollout-canary
  namespace: rollouts-demo
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: rollout-canary
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-canary
  namespace: rollouts-demo
spec:
  replicas: 5
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: rollout-canary
  template:
    metadata:
      labels:
        app: rollout-canary
    spec:
      containers:
      - name: rollouts-demo
        image: argoproj/rollouts-demo:blue
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        resources:
          requests:
            memory: 32Mi
            cpu: 5m
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 30s}
      - setWeight: 40
      - pause: {duration: 30s}
      - setWeight: 60
      - pause: {duration: 30s}
      - setWeight: 80
      - pause: {duration: 30s}
```

### 4.2 Apply Canary Rollout

```bash
kubectl apply -f rollout-canary.yaml
```

### 4.3 Watch Initial Deployment

```bash
kubectl argo rollouts get rollout rollout-canary -n rollouts-demo --watch
```

Wait for the rollout to complete (all pods running).

### 4.4 Trigger Canary Update

```bash
kubectl argo rollouts set image rollout-canary -n rollouts-demo \
  rollouts-demo=argoproj/rollouts-demo:yellow
```

### 4.5 Watch Canary Progression

```bash
kubectl argo rollouts get rollout rollout-canary -n rollouts-demo --watch
```

You'll see:
- **Step 1:** 20% traffic to new version (1 of 5 pods)
- **Step 2:** Pause for 30 seconds
- **Step 3:** 40% traffic (2 of 5 pods)
- And so on...

### 4.6 Access During Canary

```bash
kubectl port-forward -n rollouts-demo svc/rollout-canary 8082:80
```

Refresh `http://localhost:8082` multiple times - you'll see a mix of blue and yellow!

---

## Step 5: Manual Promotion and Abort

### 5.1 Create a Rollout with Manual Steps

Update the canary rollout to require manual promotion:

```yaml
strategy:
  canary:
    steps:
    - setWeight: 20
    - pause: {}  # Pause indefinitely, requires manual promotion
    - setWeight: 50
    - pause: {}
    - setWeight: 100
```

Apply:

```bash
kubectl apply -f rollout-canary.yaml
```

### 5.2 Trigger Update

```bash
kubectl argo rollouts set image rollout-canary -n rollouts-demo \
  rollouts-demo=argoproj/rollouts-demo:red
```

### 5.3 Watch and Promote

Watch the rollout:

```bash
kubectl argo rollouts get rollout rollout-canary -n rollouts-demo --watch
```

It will pause at 20%. Manually promote:

```bash
kubectl argo rollouts promote rollout-canary -n rollouts-demo
```

### 5.4 Abort a Rollout

If you need to abort (rollback):

```bash
kubectl argo rollouts abort rollout-canary -n rollouts-demo
```

This reverts to the previous version immediately!

---

## Step 6: Automated Analysis with Prometheus

### 6.1 Prerequisites

Ensure Prometheus is running from Bonus Lab 1:

```bash
kubectl get pods -n monitoring
```

If not, deploy Prometheus first.

### 6.2 Create AnalysisTemplate

Create `analysis-template.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
  namespace: rollouts-demo
spec:
  metrics:
  - name: success-rate
    interval: 30s
    count: 3
    successCondition: result[0] >= 0.95
    failureLimit: 1
    provider:
      prometheus:
        address: http://prometheus.monitoring.svc.cluster.local:9090
        query: |
          sum(rate(http_requests_total{status=~"2.."}[5m])) 
          / 
          sum(rate(http_requests_total[5m]))
```

Apply:

```bash
kubectl apply -f analysis-template.yaml
```

### 6.3 Update Canary to Use Analysis

Update `rollout-canary.yaml`:

```yaml
strategy:
  canary:
    steps:
    - setWeight: 20
    - pause: {duration: 1m}
    - analysis:
        templates:
        - templateName: success-rate
    - setWeight: 50
    - pause: {duration: 1m}
    - setWeight: 100
```

### 6.4 Rollout with Analysis

Apply and trigger an update:

```bash
kubectl apply -f rollout-canary.yaml
kubectl argo rollouts set image rollout-canary -n rollouts-demo \
  rollouts-demo=argoproj/rollouts-demo:orange
```

The rollout will automatically validate success rate before progressing!

---

## Step 7: Integrate with Argo CD

### 7.1 Create Argo CD Application for Rollout

Create a Git repository structure:

```
rollouts-app/
├── rollout.yaml
└── service.yaml
```

### 7.2 Create Application

Create `rollout-app-argocd.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: rollout-demo
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/rollouts-demo.git
    targetRevision: HEAD
    path: examples/bluegreen
  destination:
    server: https://kubernetes.default.svc
    namespace: rollouts-demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

Apply:

```bash
kubectl apply -f rollout-app-argocd.yaml
```

### 7.3 View in Argo CD UI

1. Open Argo CD UI
2. Find the `rollout-demo` application
3. Argo CD recognizes Rollouts and shows deployment steps!

---

## Step 8: Rollout Dashboard

### 8.1 Access Rollouts Dashboard

```bash
kubectl argo rollouts dashboard -n rollouts-demo
```

This opens a web UI at `http://localhost:3100`

### 8.2 Explore Dashboard

The dashboard shows:
- All rollouts in the namespace
- Current status and revision
- Visual representation of deployment steps
- Ability to promote/abort from UI

---

## Step 9: Advanced Rollout Strategies

### 9.1 Experiment with Traffic Management

For advanced traffic management, Argo Rollouts integrates with:

- **Istio** - Service mesh traffic routing
- **Nginx Ingress** - Ingress-based traffic splitting
- **AWS ALB** - Application Load Balancer
- **Traefik** - Traefik ingress controller

### 9.2 Example: Blue/Green with Istio

```yaml
strategy:
  blueGreen:
    activeService: rollout-active
    previewService: rollout-preview
    trafficRouting:
      istio:
        virtualService:
          name: rollout-vsvc
          routes:
          - primary
```

---

## Exercises

### Exercise 1: Create Your Own Rollout

1. Create a Rollout for the microservices demo frontend
2. Implement a canary strategy with 4 steps
3. Test updating the image version

### Exercise 2: Implement Analysis

1. Create an AnalysisTemplate that checks pod CPU usage
2. Add it to your canary rollout
3. Trigger an update and watch automatic validation

### Exercise 3: Blue/Green with Preview

1. Deploy a blue/green rollout
2. Update the image
3. Test the preview service
4. Promote or abort based on testing

---

## Verification Checklist

- [ ] Argo Rollouts installed and running
- [ ] Can create blue/green rollout
- [ ] Can switch traffic with promotion
- [ ] Can create canary rollout
- [ ] Understand progressive traffic shifting
- [ ] Can abort and rollback deployments
- [ ] Understand analysis templates
- [ ] Rollout dashboard accessible

---

## Troubleshooting

### Problem: Rollout stuck in Progressing

**Solution:** Check pod status:
```bash
kubectl get pods -n rollouts-demo
kubectl describe pod <pod-name> -n rollouts-demo
```

### Problem: Cannot promote rollout

**Solution:** Check rollout status:
```bash
kubectl argo rollouts get rollout <name> -n rollouts-demo
kubectl argo rollouts status <name> -n rollouts-demo
```

### Problem: Analysis failing

**Solution:** Check analysis run:
```bash
kubectl get analysisrun -n rollouts-demo
kubectl describe analysisrun <run-name> -n rollouts-demo
```

---

## Clean Up

```bash
# Delete rollouts
kubectl delete namespace rollouts-demo

# Delete Argo Rollouts (optional)
kubectl delete namespace argo-rollouts

# Stop port forwards
pkill -f "port-forward.*8080"
pkill -f "port-forward.*8081"
pkill -f "port-forward.*8082"
```

---

## What's Next?

You've completed all bonus labs! Consider:
- Explore Istio integration for advanced traffic management
- Implement Analysis Templates with real metrics
- Deploy rollouts with Argo CD in production
- Experiment with different rollout strategies

---

## Key Takeaways

✅ Argo Rollouts enables progressive delivery  
✅ Blue/Green deployments reduce deployment risk  
✅ Canary deployments provide gradual rollout  
✅ Automated analysis validates deployments  
✅ Manual promotion provides control gates  
✅ Integrates seamlessly with Argo CD  
✅ Rollout dashboard provides visual management  
✅ Essential for production-grade deployments

---

## Additional Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Rollout Strategies](https://argoproj.github.io/argo-rollouts/features/specification/)
- [Analysis Templates](https://argoproj.github.io/argo-rollouts/features/analysis/)
- [Traffic Management](https://argoproj.github.io/argo-rollouts/features/traffic-management/)
- [Rollouts Demo App](https://github.com/argoproj/rollouts-demo)
