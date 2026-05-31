# My Deep Learning Fundamentals Notes

This repository is my personal fork of the [Microsoft AI-For-Beginners](https://github.com/microsoft/AI-For-Beginners) course. 
I am using this to track my progress and keep my interactive notebooks in sync with Google Colab.

---

## ⚠️ FOR VISITORS: Do Not Fork This Repository!
If you fork this repository, you will copy all of my personal practice notes. 
If you want to create your own isolated, highly-optimized learning environment that syncs perfectly between **VS Code** and **Google Colab**, you can use my custom automation tool.

### How to Replicate My Setup
I created a powerful Bash script that automates the complex Git architecture (forking the official curriculum, configuring sparse-checkout to save disk space, setting up upstream remotes, and syncing).

**Run this in your terminal to set up your own environment:**
```bash
# 1. Ensure you have the GitHub CLI installed and authenticated:
gh auth login

# 2. Download my automation script:
mkdir -p ~/learning
curl -o ~/learning/learning_helper.sh https://raw.githubusercontent.com/saquib-byte/Deep-Learning-Fundamentals/main/WORKFLOW_DOCS/learning_helper.sh
chmod +x ~/learning/learning_helper.sh

# 3. Run the script and choose "Option 1" to setup your course!
~/learning/learning_helper.sh
```
*(The script will ask for the official repo `microsoft/AI-For-Beginners` and fork it directly to your account!)*

---

## My Workflow
1. **Never edit the original notebooks directly!** Always duplicate a notebook before working on it (e.g., `lesson_practice.ipynb`).
2. **Commit and Push:** After working locally or in Colab, run the helper script to sync progress.
3. **Open in Colab:** Navigate to `https://colab.research.google.com/github/saquib-byte/Deep-Learning-Fundamentals`.
