# Syncing Workflow: VS Code & Google Colab

This document outlines the standard operating procedure for maintaining synchronization between your local VS Code environment and Google Colab cloud compute.

## 1. Naming Conventions
**Never edit the original course notebooks.** If Microsoft updates the original repository, any edits you made to the original files will cause Git merge conflicts.
- **Protocol:** Duplicate the notebook you wish to study.
- **Suffix Rule:** Append `_practice` or `_notes` to the filename (e.g., `Perceptron_practice.ipynb`). This ensures your files sort alphabetically directly underneath the original course files.

## 2. Working Locally (VS Code)
When working locally, you are utilizing your machine's native hardware (RTX GPU).
1. Open the notebook in VS Code.
2. When finished, open the VS Code terminal.
3. Execute the following commands to save your progress to the cloud:
   ```bash
   git add .
   git commit -m "Update practice notebooks"
   git push origin main
   ```

## 3. Working in the Cloud (Google Colab)
When you require cloud computing resources, use Google Colab.
1. Navigate to `colab.research.google.com`.
2. Select the **GitHub** tab and search for your repository: `saquib-byte/Deep-Learning-Fundamentals`.
3. Open your desired `_practice.ipynb` notebook.
4. **To Save:** Click `File -> Save a copy in GitHub`.
   - Ensure the repository selected is `saquib-byte/Deep-Learning-Fundamentals`.
   - Ensure the file path accurately reflects the folder structure so it remains organized.

## 4. Syncing Colab Changes Back to VS Code
After saving from Colab, the updated file exists on GitHub's servers, not your local machine. Before starting your next local session, you must sync the changes:
1. Open the VS Code terminal in the course directory.
2. Execute:
   ```bash
   git pull
   ```
3. Your local files are now up to date with your Colab progress.
