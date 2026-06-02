# Storage Optimization (Sparse Checkout)

This document details the configuration used to minimize local storage consumption by excluding non-English course translations, and provides step-by-step instructions on setting this up from scratch.

## 1. The Problem
The official Microsoft course includes translations in dozens of languages (e.g., `zh-cn`, `ja`, `ko`), which bloats the repository size significantly.

## 2. The Solution: Git Sparse-Checkout
Rather than permanently deleting these translation folders from your remote GitHub repository (which would cause massive merge conflicts if Microsoft updates those files), this local clone utilizes a feature called **Git Sparse-Checkout**.

### How it Works
Sparse-Checkout instructs your local Git client to essentially "hide" specific directories from your local filesystem while maintaining their existence in the Git history and on your remote GitHub repository.

---

## 3. Step-by-Step Setup Guide

### Option A: Setup from Scratch (Cloning a new repo)
If you need to clone the repository to another machine in the future:
```bash
# 1. Clone without checking out files immediately to save time and disk space
git clone --no-checkout https://github.com/<your-github-username>/<your-repo-name>.git microsoft_ai_for_beginners
cd microsoft_ai_for_beginners

# 2. Initialize sparse checkout in pattern (non-cone) mode
git sparse-checkout init --no-cone

# 3. Configure the exclusion patterns in .git/info/sparse-checkout
echo "/*" > .git/info/sparse-checkout
echo "!/translations/" >> .git/info/sparse-checkout
echo "!/translated_images/" >> .git/info/sparse-checkout

# 4. Checkout the main branch (this will download everything EXCEPT the excluded directories)
git checkout main
```

### Option B: Configure on an Existing Clone
If the repository is already cloned but contains all translation files:
```bash
# 1. Configure the local repository to use non-cone mode
git config --worktree core.sparseCheckoutCone false

# 2. Add patterns to the sparse-checkout configuration file (.git/info/sparse-checkout)
echo "/*" > .git/info/sparse-checkout
echo "!/translations/" >> .git/info/sparse-checkout
echo "!/translated_images/" >> .git/info/sparse-checkout

# 3. Re-apply the sparse checkout config to purge excluded files from the filesystem
git sparse-checkout reapply
```

---

## 4. Frequently Asked Questions

### Does my remote fork have all languages or only selected?
**Your remote fork on GitHub has ALL languages.** 
Forking a repository creates a complete server-side duplicate of the original repository on GitHub's servers. Sparse-checkout is a **local-only** git client setting. It does not modify or delete files on the remote GitHub repository itself. This ensures that:
- Your GitHub repository remains 100% compatible with updates from Microsoft's upstream repository.
- Google Colab can interact with your repository normally since the remote copy is complete.

### If I pull updates from my fork, will it download the excluded languages?
**No.** 
When you run `git pull`, Git fetches updates from the remote fork, but when it checks out the new files to your local hard drive, it respects your local sparse-checkout rules.
Even if someone else pushed changes to the `translations/` folder on GitHub, Git will not download or create those files/folders in your local workspace. They remain excluded on your local machine.

### How to verify your current checkout status
Run `git status` inside your local repository. You should see a line confirming:
`You are in a sparse checkout with 3% of tracked files present.`

