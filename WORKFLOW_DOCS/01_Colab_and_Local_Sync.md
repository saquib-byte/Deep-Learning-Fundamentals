# Syncing Workflow: VS Code & Google Colab

This document outlines the standard operating procedure for maintaining synchronization between your local VS Code environment and Google Colab cloud compute.

## 1. Naming Conventions
**Never edit the original course notebooks.** If Microsoft updates the original repository, any edits you made to the original files will cause Git merge conflicts.
- **Protocol:** Duplicate the notebook you wish to study.
- **Suffix Rule:** Append `_practice` or `_notes` to the filename (e.g., `Perceptron_practice.ipynb`). This ensures your files sort alphabetically directly underneath the original course files.

## 2. Working Locally (VS Code)
When working locally, you are utilizing your machine's native hardware (RTX GPU).
1. **Install Prerequisites:** Open VS Code, go to the **Extensions tab** (the 4 squares icon on the left sidebar), and download the official **Python** and **Jupyter** extensions provided by Microsoft.
2. Open the `.ipynb` notebook in VS Code and do your practice.
3. When finished, you must save your progress to the cloud. You can open the VS Code terminal using the shortcut `` Ctrl + ` `` (Control + Backtick), or by clicking **Terminal -> New Terminal** from the top menu.
4. Execute the following commands in the terminal:
   ```bash
   git add .
   git commit -m "Update practice notebooks"
   git push origin main
   ```

## 3. Working in the Cloud (Google Colab)
When you require cloud computing resources, use Google Colab.
1. Navigate to `colab.research.google.com`.
2. Select the **GitHub** tab and search for your forked repository (e.g., `<your-github-username>/AI-For-Beginners` or whatever you renamed it to).
3. Open your desired `_practice.ipynb` notebook.
4. **To Save:** Click `File -> Save a copy in GitHub`.
   - Ensure the repository selected is your personal fork: `<your-github-username>/<your-repo-name>`.
   - Ensure the file path accurately reflects the folder structure so it remains organized.

## 4. Syncing Colab Changes Back to VS Code
After saving from Colab, the updated file exists on GitHub's servers, not your local machine. Before starting your next local session, you must sync the changes:
1. Open VS Code.
2. Go to the top left and click **File -> Open Folder...** and select your working directory (e.g., `~/learning/ai_ml/microsoft_ai_for_beginners`).
3. Open the terminal. You can do this by:
   - Using the keyboard shortcut: `` Ctrl + ` `` (Control + Backtick)
   - OR clicking **Terminal -> New Terminal** from the top menu bar.
4. Execute the following command in the terminal:
   ```bash
   git pull
   ```
5. Your local files are now perfectly synced with your Colab progress!

---

## 5. Sync or Run via the Learning Environment Helper (Automated Option)
Instead of running manual Git commands, you can use the interactive helper script located at `~/learning/learning_helper.sh`. This script dynamically supports both Browser Colab (GitHub sync) and Colab CLI (terminal/IDE connection) workflows:

1. Run the script:
   ```bash
   ~/learning/learning_helper.sh
   ```
2. Choose option `2` (`Sync or Run on Google Colab`).
3. Select your course repository.
4. Choose your preferred interaction method:
   - **Browser Colab:** Proceed with pulling/pushing your practice notebooks via GitHub.
   - **Colab CLI:** Open the Colab CLI sub-menu to provision VMs, execute scripts, and download files directly from your terminal.

For full instructions and a detailed breakdown of all available options, please refer to the **[Main Setup Guide](../SETUP_GUIDE.md#2-using-the-learning-environment-helper)**.

---

## 6. Working in VS Code/Terminal via Google Colab CLI
The **Google Colab CLI** is a terminal-based tool that connects your local machine directly to remote Colab runtimes. This lets you write and edit notebooks/scripts in VS Code locally, while running the computations on Colab's cloud GPUs without ever leaving your IDE.

### 1. Installation & Setup
To use this integration, make sure the `colab` CLI tool is installed locally:
```bash
# Using pip
pip install google-colab-cli

# Or using uv (recommended)
uv tool install google-colab-cli
```

### 2. Workflow Steps
Using the helper script (Option 2 -> Option 2: Colab CLI), you can run the following commands:
1. **Start VM:** Choose option `1` (`Start/Provision a new Colab VM`) and select your GPU type (T4, L4, or A100).
2. **Execute File:** Choose option `3` (`Execute Notebook/Script remotely`). Select your practice notebook or Python script from the automatic file list. The script will be run on the remote VM, outputting directly to your local terminal.
3. **Download Output/Logs:** Choose option `6` (`Download files/logs from Colab VM`) to pull model weights (checkpoints) or logs back to your local folder.
4. **Stop VM:** Always stop the session when finished using option `5` (`Stop/Terminate Colab VM`) to avoid wasting Colab compute units!

---

## 7. Hardware & GPU Requirements (VRAM Breakdown)

To run the Deep Learning and Neural Network notebooks smoothly, a dedicated GPU is highly recommended. Below is the hardware compatibility matrix for this course:

| Hardware Component | Support Status | Recommendation for this Course |
|--------------------|----------------|--------------------------------|
| **NVIDIA GPU** | ✅ **Native Support** | **Recommended for Local.** PyTorch and TensorFlow support CUDA out of the box. |
| **AMD GPU** | ⚠️ **Partial Support** | **Cloud Recommended.** AMD is supported on Linux via ROCm, but setup is complex for beginners. Use Google Colab instead. |
| **Intel / Apple Silicon**| ⚠️ **Partial Support** | **Cloud Recommended.** Mac M1/M2/M3 (MPS) works for PyTorch but has limitations. Intel GPUs are too slow for heavy deep learning. |
| **Low-End / CPU Only** | ❌ **Not Supported** | **Cloud Required.** Training Neural Networks on a CPU will be painfully slow. You must use Google Colab. |

### Minimum VRAM Breakdown by Module
If you are using an NVIDIA GPU locally, here is exactly what VRAM capacity you will need based on the course modules:

* **Basic ML & Intro to Neural Networks (Lessons 1-3): `4GB VRAM`**
  * You can comfortably run these notebooks (e.g., Perceptron, Intro to Keras/PyTorch) locally on entry-level GPUs like a GTX 1050Ti or GTX 1650.
* **Computer Vision CNNs & Object Detection (Lesson 4): `6GB VRAM`**
  * Training Convolutional Neural Networks and Object Detection models requires larger batch sizes. GPUs like the RTX 2060, RTX 3050, or RTX 4050 are recommended here. If you have 4GB VRAM, you *might* survive by drastically reducing your batch size, but it will be very slow.
* **Advanced GANs, Transfer Learning, & NLP Transformers (Lessons 4.10, 5.18): `8GB+ VRAM`**
  * These are massively demanding architectures. If you try to run these on less than 8GB, you will likely face `CUDA OutOfMemoryError` crashes. You **must** have an RTX 3060, RTX 4060, or better. 
  * *If you have less than 8GB VRAM, we strongly mandate that you use Google Colab for these specific notebooks!*

