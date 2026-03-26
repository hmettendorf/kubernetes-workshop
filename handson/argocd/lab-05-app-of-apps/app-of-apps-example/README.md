# App of Apps Example

This repository demonstrates the App of Apps pattern with ArgoCD.

## Structure

```
app-of-apps-example/
├── README.md                   # This file
├── root-app.yaml              # Root Application (deploy this to ArgoCD)
└── apps/                      # Child applications
    ├── infrastructure/        # Infrastructure layer
    │   ├── infra-app-1.yaml   # Demo app (guestbook)
    │   └── infra-app-2.yaml   # Demo app (helm-guestbook)
    ├── platform/             # Platform services layer
    │   ├── platform-app-1.yaml  # Demo app (guestbook)
    │   └── platform-app-2.yaml  # Demo app (helm-guestbook)
    └── applications/         # Application layer
        ├── frontend.yaml      # Demo app (guestbook)
        └── backend.yaml       # Demo app (helm-guestbook)
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
- Infrastructure layer: infra-app-1, infra-app-2
- Platform layer: platform-app-1, platform-app-2
- Application layer: app-frontend, app-backend

## Deployment Order

Applications are deployed in waves using sync-wave annotations:
- Wave 1: Infrastructure (infra-app-1, infra-app-2)
- Wave 2: Platform (platform-app-1, platform-app-2)
- Wave 3: Applications (app-frontend, app-backend)

This ensures dependencies are met before dependent services start.

## Customization

To add a new application:
1. Create a new Application YAML file in the appropriate directory
2. Set the sync-wave annotation appropriately
3. Commit and push
4. ArgoCD will automatically detect and deploy it!

## Notes

- All applications in this example use the `argoproj/argocd-example-apps` repository
- **These are demo apps (guestbook)** - not real infrastructure components
- The names (infra-app-1, platform-app-1, etc.) represent the **layer/tier**, not the actual technology
- This is for demonstration purposes to show the App of Apps pattern
- In production, point to your actual application repositories
- Adjust sync policies (auto-sync, prune, self-heal) as needed
