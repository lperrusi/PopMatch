# GitHub Repository Setup Guide

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the "+" icon in the top right → "New repository"
3. Repository name: `PopMatch` (or your preferred name)
4. Description: "AI-powered movie and TV show discovery app built with Flutter"
5. Choose visibility: **Private** (recommended) or **Public**
6. **DO NOT** initialize with README, .gitignore, or license (we already have these)
7. Click "Create repository"

## Step 2: Push to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/PopMatch.git

# Rename branch to main (if needed)
git branch -M main

# Push code
git push -u origin main
```

Or if you prefer SSH:

```bash
git remote add origin git@github.com:YOUR_USERNAME/PopMatch.git
git branch -M main
git push -u origin main
```

## Quick Setup Script

Run this after creating the repository (replace YOUR_USERNAME):

```bash
cd /Users/lucasperrusi/Projects/PopMatch
git remote add origin https://github.com/YOUR_USERNAME/PopMatch.git
git branch -M main
git push -u origin main
```

## Important Notes

✅ **Sensitive files are excluded**:
- `GoogleService-Info.plist` (Firebase config) - **NOT in repository**
- API keys in code should be moved to environment variables in production

⚠️ **Before pushing to public repo**:
- Consider removing hardcoded TMDB API key from `lib/services/tmdb_service.dart`
- Move API keys to environment variables or secure storage
- Review all files for sensitive information

## Repository Structure

The repository includes:
- ✅ Complete Flutter app source code
- ✅ Documentation (README, setup guides)
- ✅ Firebase Cloud Functions code
- ✅ Test files
- ✅ Assets and images
- ✅ Configuration files

Excluded (via .gitignore):
- ❌ Build artifacts
- ❌ Firebase config files
- ❌ Dependencies (node_modules, Pods)
- ❌ User data
- ❌ IDE settings
