# Web Deployment Guide - Infinite Brain Challenge

## Current Status
- **Web build:** READY at `build/web/`
- **Main branch:** Source code (commit `dea9bc0`)
- **gh-pages branch:** Web build ready for GitHub Pages (commit `8fa05b7`)
- **Base href:** `/infinite-brain-challenge/`

---

## DEPLOY NOW — 3 Steps

### Step 1: Create GitHub Repository
1. Go to https://github.com/new
2. Repository name: `infinite-brain-challenge`
3. Leave it **empty** (no README, no .gitignore, no license)
4. Click **Create repository**

### Step 2: Push Both Branches (run these commands)
```bash
cd C:\Users\dell\Downloads\infinite_brain_challenge

# Add your GitHub remote (replace kmeshal2024)
git remote add origin https://github.com/kmeshal2024/infinite-brain-challenge.git

# Push source code
git push -u origin main

# Push web build for GitHub Pages
git push origin gh-pages
```

### Step 3: Enable GitHub Pages
1. Go to your repo on GitHub
2. Click **Settings** (top tab)
3. Click **Pages** (left sidebar)
4. Under "Build and deployment":
   - Source: **Deploy from a branch**
   - Branch: **gh-pages** / **(root)**
5. Click **Save**
6. Wait 1-2 minutes

---

## Your Live URL
```
https://kmeshal2024.github.io/infinite-brain-challenge/
```

---

## Future Updates

To redeploy after code changes:
```bash
# On main branch, after making changes:
flutter clean && flutter pub get
MSYS_NO_PATHCONV=1 flutter build web --release --base-href "/infinite-brain-challenge/"

# Switch to gh-pages and update
git checkout gh-pages
git rm -rf .
cp -r build/web/* .
cp index.html 404.html
touch .nojekyll
git add -A
git commit -m "Update web build"
git push origin gh-pages --force
git checkout main
```

Or use the deploy script:
```bash
bash deploy_web.sh
```

---

## Notes
- The `404.html` is a copy of `index.html` — this enables SPA routing on GitHub Pages
- `.nojekyll` prevents GitHub from running Jekyll processing on the files
- The web version works fully offline after first load (PWA support)
- SharedPreferences data persists via browser localStorage
