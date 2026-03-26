#!/bin/bash
# Setup script for App of Apps example

set -e

echo "=== App of Apps Setup ==="
echo ""

# Check if git is initialized
if [ ! -d .git ]; then
    echo "Initializing Git repository..."
    git init
    echo "✓ Git initialized"
else
    echo "✓ Git already initialized"
fi

# Check for remote
if ! git remote get-url origin &>/dev/null; then
    echo ""
    echo "Please enter your Git repository URL:"
    echo "Example: https://github.com/YOUR-USERNAME/app-of-apps-example.git"
    read -p "Repository URL: " REPO_URL
    
    if [ -n "$REPO_URL" ]; then
        git remote add origin "$REPO_URL"
        echo "✓ Remote added: $REPO_URL"
        
        # Update root-app.yaml with the repository URL
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|https://github.com/YOUR-USERNAME/app-of-apps-example.git|$REPO_URL|g" root-app.yaml
        else
            # Linux
            sed -i "s|https://github.com/YOUR-USERNAME/app-of-apps-example.git|$REPO_URL|g" root-app.yaml
        fi
        echo "✓ Updated root-app.yaml with repository URL"
    else
        echo "⚠ Skipping remote configuration"
    fi
else
    CURRENT_REMOTE=$(git remote get-url origin)
    echo "✓ Remote already configured: $CURRENT_REMOTE"
fi

# Add and commit files
echo ""
echo "Adding files to git..."
git add .

if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "✓ No changes to commit"
else
    echo "Committing files..."
    git commit -m "Initial app of apps structure" || true
    echo "✓ Files committed"
fi

# Check for main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo ""
    read -p "Switch to 'main' branch? (y/n): " SWITCH_BRANCH
    if [ "$SWITCH_BRANCH" = "y" ]; then
        git branch -M main
        echo "✓ Switched to main branch"
    fi
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Push to remote: git push -u origin main"
echo "2. Deploy root app: kubectl apply -f root-app.yaml"
echo "3. Watch in ArgoCD UI!"
echo ""
