# Storage Optimization (Sparse Checkout)

This document details the configuration used to minimize local storage consumption by excluding non-English course translations.

## The Problem
The official Microsoft course includes translations in dozens of languages (e.g., `zh-cn`, `ja`, `ko`), which bloats the repository size significantly.

## The Solution: Git Sparse-Checkout
Rather than permanently deleting these translation folders from your GitHub repository (which would cause massive merge conflicts if Microsoft updates those files), this local clone utilizes a feature called **Git Sparse-Checkout**.

### How it Works
Sparse-Checkout instructs your local Git client to essentially "hide" specific directories from your local filesystem while maintaining their existence in the Git history and on your remote GitHub repository.

### Current Configuration
The sparse-checkout file (located secretly in `.git/info/sparse-checkout`) is configured with the following exclusion rules:
- `!/translations/`
- `!/translated_images/`

When you run `git push`, it securely uploads your notebook changes to GitHub without interfering with the hidden translation files. This keeps your local `ai_ml` folder extremely lightweight while maintaining full compatibility with the upstream repository.
