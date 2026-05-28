# Repository Architecture

This document explains how your local learning environment is connected to the official Microsoft curriculum.

## The Three-Tier Architecture

1. **Upstream (Microsoft's Repository)**
   - `https://github.com/microsoft/AI-For-Beginners`
   - This is the official source of truth. Microsoft periodically updates this repository with new lessons or fixes.

2. **Origin (Your Personal Fork)**
   - `https://github.com/saquib-byte/Deep-Learning-Fundamentals`
   - This is a 1:1 copy of the Upstream repository that lives on your personal GitHub account. Google Colab reads from and writes to this specific repository.

3. **Local (VS Code Workspace)**
   - `/home/nobara/learning/ai_ml/microsoft_ai_for_beginners`
   - This is the clone residing on your physical hard drive. It pushes to and pulls from your Origin fork.

## Fetching Upstream Updates
If Microsoft releases an update that you wish to pull into your learning environment:
1. Go to your GitHub repository page (`saquib-byte/Deep-Learning-Fundamentals`).
2. Click the **Sync fork** button near the top of the code page to pull Microsoft's changes into your fork.
3. Open your local VS Code terminal and run `git pull` to download those updates to your machine.
