# 🚀 Workspace Setup & Automation Guide

Welcome to your optimized Deep Learning workspace! This document explains exactly how to set up your environment, how the automation script works, and what Git commands it runs under the hood.

---

## 1. Prerequisites (Highly Recommended)

Before running the automation script, we highly recommend installing the necessary tools and authenticating your terminal manually. *(Note: The script has a built-in safety net that will try to prompt you for these, but doing it manually is best practice!)*

### Step 1: Install Git & GitHub CLI

- **Windows:** Open PowerShell and run:
  ```powershell
  winget install --id Git.Git -e --source winget
  winget install --id GitHub.cli
  ```
- **macOS:** Open Terminal and run `brew install git gh`
- **Linux:** Use your package manager (e.g., `sudo apt install git gh` or `sudo dnf install git gh`)

### Step 2: Authenticate with GitHub

Link your terminal to your GitHub account by running:

```bash
gh auth login
```

*(Follow the interactive prompts to log in via your web browser)*

---

## 2. Using the Learning Environment Helper

Your workspace is managed by `learning_helper.sh`, which acts as a simple **3-Button Remote Control** for your repository.

Run the script by typing: `~/learning/learning_helper.sh` (or `bash ~/learning/learning_helper.sh` on Windows).

### 🎛️ The 3-Button Remote Control

#### Option 1: Setup a New Course

Automates the entire process of forking the official curriculum to your GitHub account and configuring sparse-checkout so you save 97% of your disk space.

#### Option 2: Sync Progress (Local <-> GitHub)

Pushes your local practice notes to GitHub, and pulls any new notes you made in Google Colab back to your local computer.

#### Option 3: Update Curriculum (Upstream)

Fetches brand new lessons and updates from the official Microsoft repository and safely merges them into your workspace without destroying your practice files.

---

## 3. What is the Script Actually Doing?

If you are curious about what happens behind the scenes, here are the raw Git commands the script runs for you when you push those buttons:

* **Storage Optimization (Option 1):** It modifies the hidden `.git/info/sparse-checkout` file to exclude massive translation folders, drastically reducing folder size.
* **Syncing (Option 2):**
  ```bash
  git add .
  git commit -m "Auto-sync practice files"
  git pull --rebase=false origin main
  git push origin main
  ```
* **Updating from Microsoft (Option 3):**
  ```bash
  git fetch upstream main
  git merge upstream/main
  git push origin main
  ```

---

## 4. How to Study (The Golden Rule)

Now that your workspace is set up, how do you actually use it?

**The Golden Rule:** Never edit the original `.ipynb` notebooks! Always duplicate them and add a `_practice` suffix (e.g., `lesson_practice.ipynb`).

For a comprehensive guide on how to safely track your notebooks and use Google Colab, please read our **[Colab and Local Sync Workflow Guide](WORKFLOW_DOCS/01_Colab_and_Local_Sync.md)**.
