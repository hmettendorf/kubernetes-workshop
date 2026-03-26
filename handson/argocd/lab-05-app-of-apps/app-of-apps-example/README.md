# App of Apps Example

This repository demonstrates the App of Apps pattern with ArgoCD.

## Structure

```
app-of-apps-example/
├── README.md                   # This file
├── root-app.yaml              # Root Application (deploy this to ArgoCD)
└── apps/                      # Child applications
    ├── infrastructure/        # Infrastructure layer
    │   ├── nginx-ingress.yaml
    │   └── cert-manager.yaml
    ├── platform/             # Platform services layer
    │   ├── redis.yaml
    │   └── postgresql.yaml
    └── applications/         # Application layer
        ├── frontend.yaml
        └── backend.yaml
```

## How to Use

### 1. Push this repository to your Git hosting service

```bash
git init
git add .
git commit -m "Initial app of apps structure"
git remote add origin <your-repo-url>
git branch -M main
git push -u origin main
```

### 2. Deploy the root application

Option A: Via kubectl
```bash
kubectl apply -f root-app.yaml
```

Option B: Via ArgoCD UI
1. Click **+ NEW APP**
2. Fill in:
   - Application Name: `root-app`
   - Project: `default`
   - Repository URL: `<your-repo-url>`
   - Revision: `main`
   - Path: `apps`
   - Cluster URL: `https://kubernetes.default.svc`
   - Namespace: `argocd`
   - Enable **Directory Recurse**
3. Click **CREATE**
4. Click **SYNC**

### 3. Watch the magic happen!

The root application will automatically create all child applications:
- Infrastructure layer: nginx-ingress, cert-manager
- Platform layer: redis, postgresql
- Application layer: frontend, backend

## Deployment Order

Applications are deployed in waves using sync-wave annotations:
- Wave 1: Infrastructure (nginx-ingress, cert-manager)
- Wave 2: Platform (redis, postgresql)
- Wave 3: Applications (frontend, backend)

This ensures dependencies are met before dependent services start.

## Customization

To add a new application:
1. Create a new Application YAML file in the appropriate directory
2. Set the sync-wave annotation appropriately
3. Commit and push
4. ArgoCD will automatically detect and deploy it!

## Notes

- All applications in this example use the `argoproj/argocd-example-apps` repository
- This is for demonstration purposes
- In production, point to your actual application repositories
- Adjust sync policies (auto-sync, prune, self-heal) as needed
