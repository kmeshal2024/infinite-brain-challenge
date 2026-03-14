#!/bin/bash
# Deploy Flutter web build to gh-pages branch for GitHub Pages
# Usage: bash deploy_web.sh
#
# Prerequisites:
#   - Git repo initialized with remote origin set
#   - Flutter web build completed

set -e

echo "=== Deploying Infinite Brain Challenge to GitHub Pages ==="

# Step 1: Build web
echo "[1/5] Building Flutter web..."
flutter clean
flutter pub get
MSYS_NO_PATHCONV=1 flutter build web --release --base-href "/infinite-brain-challenge/"

echo "[2/5] Preparing deployment..."
# Create temp directory for gh-pages content
DEPLOY_DIR=$(mktemp -d)
cp -r build/web/* "$DEPLOY_DIR/"

# Add a 404.html that redirects to index for SPA routing
cp "$DEPLOY_DIR/index.html" "$DEPLOY_DIR/404.html"

echo "[3/5] Switching to gh-pages branch..."
# Save current branch
CURRENT_BRANCH=$(git branch --show-current)

# Create orphan gh-pages branch if it doesn't exist, or switch to it
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git checkout gh-pages
    # Remove old files
    git rm -rf . 2>/dev/null || true
else
    git checkout --orphan gh-pages
    git rm -rf . 2>/dev/null || true
fi

echo "[4/5] Copying build files..."
cp -r "$DEPLOY_DIR"/* .
rm -rf "$DEPLOY_DIR"

# Add .nojekyll to prevent Jekyll processing
touch .nojekyll

# Stage and commit
git add -A
git commit -m "Deploy web build $(date +%Y-%m-%d_%H:%M:%S)"

echo "[5/5] Pushing to GitHub..."
git push origin gh-pages --force

# Switch back to main branch
git checkout "$CURRENT_BRANCH"

echo ""
echo "=== Deployment complete! ==="
echo "GitHub Pages URL: https://YOUR-USERNAME.github.io/infinite-brain-challenge/"
echo ""
echo "Make sure GitHub Pages is configured to deploy from 'gh-pages' branch in repo Settings."
