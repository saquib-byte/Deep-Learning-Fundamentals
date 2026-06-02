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

## 5. Automated Sync Option (Simplest Method)
Instead of running manual Git commands to push and pull your changes, you can use the interactive CLI helper script located at `~/learning/learning_helper.sh`:

1. Run the script:
   ```bash
   ~/learning/learning_helper.sh
   ```
2. Choose option `2` (`Sync Local <-> GitHub Fork`).
3. Select your repository from the list, and pick whether you want to **Pull**, **Push**, or **Sync Both**.

For full instructions and a detailed breakdown of all available options in the helper script, please refer to the **[Main Setup Guide](../SETUP_GUIDE.md#2-using-the-learning-environment-helper)**.

---

## 6. Hardware & GPU Requirements (VRAM Breakdown)

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

