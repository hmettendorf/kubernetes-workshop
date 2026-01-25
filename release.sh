#!/bin/bash
set -e

# Release helper script for Argo CD Workshop
# Usage: ./release.sh <version>
# Example: ./release.sh v1.0.0

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.0"
    exit 1
fi

# Validate version format
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format vX.Y.Z (e.g., v1.0.0)"
    exit 1
fi

echo "🚀 Preparing release $VERSION"
echo ""

# Check if on main/master branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
    echo "⚠️  Warning: Not on main/master branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Warning: You have uncommitted changes"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if CHANGELOG.md exists and has entry for this version
if [ ! -f CHANGELOG.md ]; then
    echo "⚠️  Warning: CHANGELOG.md not found"
    read -p "Create it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cat > CHANGELOG.md << EOF
# Changelog

All notable changes to the Argo CD Workshop will be documented in this file.

## [$VERSION] - $(date +%Y-%m-%d)

### Added
- Initial release

EOF
    fi
else
    if ! grep -q "\[$VERSION\]" CHANGELOG.md; then
        echo "⚠️  Warning: No entry for $VERSION found in CHANGELOG.md"
        echo "Please add release notes to CHANGELOG.md before continuing"
        read -p "Open CHANGELOG.md in editor? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-vim} CHANGELOG.md
        fi
    fi
fi

echo ""
echo "📋 Release Checklist:"
echo "  ✓ Version: $VERSION"
echo "  ✓ Branch: $CURRENT_BRANCH"
echo ""

# Show what will be included
echo "📦 Files to be included in release:"
echo "  - README.md"
echo "  - CHANGELOG.md"
echo "  - ARGOCD_WORKSHOP_SUMMARY.md"
echo "  - presentation/"
echo "  - handson/"
echo ""

# Preview CHANGELOG entry
echo "📝 Release notes from CHANGELOG.md:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f CHANGELOG.md ]; then
    awk '/^## \['"${VERSION:1}"'\]/{flag=1} /^## \[/{if(flag && !/^## \['"${VERSION:1}"'\]/)exit} flag' CHANGELOG.md
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "🚀 Create release $VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Release cancelled"
    exit 1
fi

echo ""
echo "Creating release..."

# Create annotated tag
echo "📌 Creating git tag..."
git tag -a "$VERSION" -m "Release $VERSION"

# Push tag
echo "⬆️  Pushing tag to remote..."
git push origin "$VERSION"

echo ""
echo "✅ Release $VERSION created successfully!"
echo ""
echo "🔄 GitHub Actions workflow will now:"
echo "  1. Generate PDF from presentation"
echo "  2. Create workshop materials archives"
echo "  3. Create GitHub Release with all assets"
echo ""
echo "📊 Monitor progress at:"
echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
echo ""
echo "📦 Release will be available at:"
echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/releases/tag/$VERSION"
echo ""
echo "🎉 Done!"
