#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Learning Environment Helper Script
# Automates forking, sparse-checkout cloning, and syncing.
# ==============================================================================

# ANSI Color Codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper output functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check dependencies
check_dependencies() {
    local missing=0
    
    # Suggest installer command based on OS
    local installer=""
    local gh_pkg="gh"
    if command -v winget &> /dev/null; then
        installer="winget install --id"
        gh_pkg="GitHub.cli"
    elif command -v apt &> /dev/null; then
        installer="sudo apt install"
    elif command -v dnf &> /dev/null; then
        installer="sudo dnf install"
    elif command -v pacman &> /dev/null; then
        installer="sudo pacman -S"
        gh_pkg="github-cli"
    elif command -v brew &> /dev/null; then
        installer="brew install"
    fi

    if ! command -v git &> /dev/null; then
        warn "'git' is not installed."
        [[ -n "$installer" ]] && info "Try running: $installer git" || info "Download from: https://git-scm.com/"
        missing=1
    else
        local git_version
        git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local major minor
        major=$(echo "$git_version" | cut -d. -f1)
        minor=$(echo "$git_version" | cut -d. -f2)
        if [ "$major" -lt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -lt 37 ]; }; then
            error "Git version $git_version detected. This script requires Git 2.37+ for sparse-checkout. Please upgrade Git."
        fi
    fi

    if ! command -v gh &> /dev/null; then
        warn "'gh' (GitHub CLI) is not installed."
        [[ -n "$installer" ]] && info "Try running: $installer $gh_pkg" || info "Download from: https://cli.github.com/"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        error "Please install the missing dependencies and run the script again."
    fi

    if ! gh auth status &> /dev/null; then
        warn "You are not logged into GitHub CLI."
        info "Authenticating now... Please follow the prompts."
        gh auth login || error "Failed to authenticate with GitHub CLI."
    fi
}

show_menu() {
    echo -e "\n============================================="
    echo -e "      🧠 Learning Environment Helper 🧠      "
    echo -e "============================================="
    echo -e "1) 🚀 Fork & Setup a New Course (Sparse Checkout)"
    echo -e "2) 🔄 Sync or Run on Google Colab"
    echo -e "3) 🌐 Update Fork from Microsoft/Upstream"
    echo -e "4) 📊 Workspace Status (Ahead/Behind/Uncommitted)"
    echo -e "5) 🚪 Exit"
    echo -n "Select an option [1-5]: "
}

setup_new_course() {
    check_dependencies
    
    echo -e "\n--- Course Setup ---"
    read -p "Enter upstream repository URL (e.g., microsoft/AI-For-Beginners): " upstream_repo
    read -p "Enter category folder (e.g., ai_ml): " category
    read -p "Enter course folder name in snake_case (e.g., microsoft_ai_for_beginners): " folder_name

    target_dir="$HOME/learning/$category/$folder_name"

    if [ -d "$target_dir" ]; then
        error "Directory $target_dir already exists!"
    fi

    info "Forking $upstream_repo on GitHub..."
    local fork_url
    fork_url=$(gh repo fork "$upstream_repo" --clone=false --json url -q .url 2>/dev/null || true)
    
    if [ -z "$fork_url" ]; then
        # Check if they already forked it
        local repo_name
        repo_name=$(basename "$upstream_repo")
        local username
        username=$(gh api user -q .login)
        if gh repo view "$username/$repo_name" &>/dev/null; then
            warn "Fork already exists. Using your existing fork..."
            fork_url=$(gh repo view "$username/$repo_name" --json url -q .url)
        else
            error "Failed to fork repository. Ensure the URL is correct and you have permission."
        fi
    fi
    success "Fork located: $fork_url"

    info "Creating target directory and initializing sparse-checkout..."
    mkdir -p "$target_dir"
    cd "$target_dir" || error "Failed to navigate to target directory."

    # Perform sparse checkout clone
    git clone --no-checkout "$fork_url" .
    git config core.sparseCheckout true
    
    # Configure exclusions
    echo "/*" > .git/info/sparse-checkout
    
    echo -e "\n--- Language Customization ---"
    read -p "Exclude translation folders to save disk space? [Y/n]: " opt_exclude
    opt_exclude=${opt_exclude:-Y}
    if [[ "$opt_exclude" =~ ^[Yy]$ ]]; then
        read -p "Any translation languages to KEEP? (comma-separated, e.g., 'es,ar' or leave empty for English-only): " keep_langs
        if [ -n "$keep_langs" ]; then
            # Exclude all subdirectories of translations first
            echo "!/translations/*/" >> .git/info/sparse-checkout
            echo "!/translated_images/*/" >> .git/info/sparse-checkout
            # Re-include the specified languages
            IFS=',' read -ra ADDR <<< "$keep_langs"
            for lang in "${ADDR[@]}"; do
                lang_trimmed=$(echo "$lang" | xargs)
                echo "/translations/$lang_trimmed/" >> .git/info/sparse-checkout
                echo "/translated_images/$lang_trimmed/" >> .git/info/sparse-checkout
            done
            info "Configured to keep English + [$keep_langs]."
        else
            # Fully exclude translations folders
            echo "!/translations/" >> .git/info/sparse-checkout
            echo "!/translated_images/" >> .git/info/sparse-checkout
            info "Configured to keep English-only (fully excluding translation folders)."
        fi
    else
        info "Configured to keep all translation files and images."
    fi
    
    # Checkout main branch
    info "Downloading core curriculum files..."
    git checkout main
    
    # Configure upstream link
    git remote add upstream "https://github.com/${upstream_repo}.git"
    
    # Configure best practices
    git config pull.rebase false
    git config --local credential.helper cache
    git config --local merge.ours.driver true
    
    # 🛡️ Write the pre-commit hook to block original notebook edits
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/sh
staged_originals=$(git diff --cached --name-only --diff-filter=ACM | grep '^lessons/.*\.ipynb$' | grep -v '_practice\.ipynb$' || true)
if [ -n "$staged_originals" ]; then
    echo "❌ ERROR: You are attempting to commit original course notebooks!"
    echo "The golden rule is to NEVER edit the original notebooks."
    echo "Please unstage these files ('git restore --staged <file>') and rename/duplicate them with a '_practice.ipynb' suffix manually."
    echo "For full instructions, refer to: https://github.com/saquib-byte/Deep-Learning-Fundamentals/blob/main/SETUP_GUIDE.md"
    exit 1
fi
exit 0
EOF
    chmod +x .git/hooks/pre-commit

    # ⚡ Inject @saquib-byte signature to the bottom of the cloned SETUP_GUIDE
    echo -e "\n---\n*⚡ Setup fully automated & optimized using the [Learning Environment Helper](https://github.com/saquib-byte/Deep-Learning-Fundamentals) created by [@saquib-byte](https://github.com/saquib-byte).*" >> SETUP_GUIDE.md

    # ✂️ Purge inherited Microsoft workflows to save GitHub Action minutes
    if [ -d ".github/workflows" ]; then
        info "Purging inherited GitHub Actions to save free-tier minutes..."
        git rm -rf .github/workflows
    fi

    # Commit the signature and purges to their new fork immediately
    info "Saving automation signature to repository..."
    git add SETUP_GUIDE.md
    git commit -m "Initialize workspace with @saquib-byte's automation tools & purge actions"
    git push origin main
    
    echo -e "\n=========================================================================="
    success "🎉 Setup complete! You are now fully ready to learn: $(basename "$upstream_repo")"
    info "Your new learning environment is located at:"
    echo -e "${YELLOW}  $target_dir ${NC}"
    echo -e "--------------------------------------------------------------------------"
    echo -e "${GREEN}📚 What to do next:${NC}"
    echo -e "1) Open the ${YELLOW}SETUP_GUIDE.md${NC} file to understand the Golden Rules."
    echo -e "   Local: file://${target_dir}/SETUP_GUIDE.md"
    echo -e "   GitHub: https://github.com/${username}/$(basename "$upstream_repo")/blob/main/SETUP_GUIDE.md"
    echo -e "2) Read the Colab Sync Workflow to learn how to sync and save your notes."
    echo -e "   Local: file://${target_dir}/WORKFLOW_DOCS/01_Colab_and_Local_Sync.md"
    echo -e "   GitHub: https://github.com/${username}/$(basename "$upstream_repo")/blob/main/WORKFLOW_DOCS/01_Colab_and_Local_Sync.md"
    echo -e "3) NEVER edit the original notebooks. Always rename/duplicate them with '_practice.ipynb'."
    echo -e "==========================================================================\n"

    echo -e "--- 💻 Automatic Hardware Scanner ---"
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✅ NVIDIA GPU detected!${NC}"
        echo -e "You have the hardware to run all neural network lessons locally."
        echo -e "You can run this course ${YELLOW}both Locally (VS Code) and on the Cloud (Google Colab)${NC}."
    else
        echo -e "${YELLOW}⚠️ No NVIDIA GPU detected (or drivers not found).${NC}"
        echo -e "For basic ML you can run locally, but for heavy Neural Networks,"
        echo -e "${YELLOW}we strongly recommend using Google Colab (Cloud)${NC}."
        echo -e "Check PyTorch's official hardware guide here:"
        echo -e "https://pytorch.org/get-started/locally/"
    fi
    echo -e "-------------------------------------\n"

    # Open file manager based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q "microsoft" /proc/version 2>/dev/null; then
            explorer.exe "$(wslpath -w "$target_dir")" &> /dev/null || true
        else
            xdg-open "$target_dir" &> /dev/null || true
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        open "$target_dir" &> /dev/null || true
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        explorer.exe "$(cygpath -w "$target_dir")" &> /dev/null || explorer.exe "$target_dir" &> /dev/null || true
    fi
}


sync_menu() {
    echo -e "\n--- Syncing/Running Courses ---"
    # Find all Git repositories in ~/learning
    repos=()
    while IFS= read -r -d $'\0' file; do
        repos+=("$(dirname "$file")")
    done < <(find "$HOME/learning" -name ".git" -type d -print0)

    if [ ${#repos[@]} -eq 0 ]; then
        warn "No learning repositories found."
        return
    fi

    echo "Select a course repository:"
    for i in "${!repos[@]}"; do
        echo "$((i+1))) $(basename "${repos[$i]}") (${repos[$i]})"
    done
    read -p "Select course [1-${#repos[@]}]: " repo_idx

    actual_idx=$((repo_idx - 1))
    if [ $actual_idx -lt 0 ] || [ $actual_idx -ge ${#repos[@]} ]; then
        warn "Invalid selection."
        return
    fi

    repo_dir="${repos[$actual_idx]}"
    
    echo -e "\nChoose how you want to interact with Google Colab for $(basename "$repo_dir"): "
    echo "1) Browser Colab (Pull/Push changes to/from GitHub fork)"
    echo "2) Colab CLI (Execute notebooks/scripts directly from local terminal/IDE on remote Colab VM)"
    read -p "Select option [1-2]: " colab_mode
    
    case $colab_mode in
        1)
            sync_menu_options "$repo_dir"
            ;;
        2)
            manage_colab_cli "$repo_dir"
            ;;
        *)
            warn "Invalid selection."
            ;;
    esac
}

sync_menu_options() {
    local repo_dir="$1"
    cd "$repo_dir" || return

    # Ensure the attribution sticker exists before syncing
    if [[ -f "SETUP_GUIDE.md" ]] && ! grep -q "Setup fully automated & optimized using the Learning Environment Helper" SETUP_GUIDE.md; then
        echo -e "\n---\n*⚡ Setup fully automated & optimized using the [Learning Environment Helper](https://github.com/saquib-byte/Deep-Learning-Fundamentals) created by [@saquib-byte](https://github.com/saquib-byte).*" >> SETUP_GUIDE.md
    fi

    echo -e "\nSyncing options for $(basename "$repo_dir"):"
    echo "1) Pull Colab/GitHub updates (Colab -> Local)"
    echo "2) Push Local updates (Local -> GitHub)"
    echo "3) Both (Pull, then Push)"
    read -p "Select option [1-3]: " sync_opt

    case $sync_opt in
        1)
            info "Pulling updates from GitHub..."
            git pull origin main
            success "Workspace is up to date!"
            ;;
        2)
            # Check if there are unstaged/staged changes
            if git diff --quiet && git diff --cached --quiet; then
                info "No local changes to commit."
            else
                info "Staging changes..."
                git add .
                if ! git diff --cached --quiet; then
                    read -p "Enter commit message [Default: 'Update practice notebooks']: " msg
                    msg=${msg:-"Update practice notebooks"}
                    git commit -m "$msg"
                else
                    info "No changes to commit after staging."
                fi
            fi

            # Check if local is ahead of remote
            local local_ahead
            local_ahead=$(git rev-list --count origin/main..main 2>/dev/null || echo "0")
            if [ "$local_ahead" -eq 0 ]; then
                success "GitHub fork is already up to date. No push needed!"
            else
                warn "⚠️ STOP: Please review your changes in VS Code before proceeding."
                read -p "Have you manually reviewed the changes and authorize push? (y/N): " confirm
                if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                    info "Push aborted. Review your changes and run the script again."
                else
                    info "Pushing $local_ahead commit(s)..."
                    git push origin main
                    success "Pushed to GitHub fork!"
                fi
            fi
            ;;
        3)
            info "Pulling updates from GitHub..."
            git pull origin main
            
            # Check if there are unstaged/staged changes
            if git diff --quiet && git diff --cached --quiet; then
                info "No local changes to commit."
            else
                info "Staging changes..."
                git add .
                if ! git diff --cached --quiet; then
                    read -p "Enter commit message [Default: 'Update practice notebooks']: " msg
                    msg=${msg:-"Update practice notebooks"}
                    git commit -m "$msg"
                else
                    info "No changes to commit after staging."
                fi
            fi

            # Check if local is ahead of remote
            local local_ahead
            local_ahead=$(git rev-list --count origin/main..main 2>/dev/null || echo "0")
            if [ "$local_ahead" -eq 0 ]; then
                success "GitHub fork is already up to date. No push needed!"
            else
                warn "⚠️ STOP: Please review your changes in VS Code before proceeding."
                read -p "Have you manually reviewed the changes and authorize push? (y/N): " confirm
                if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                    info "Push aborted. Review your changes and run the script again."
                else
                    info "Pushing $local_ahead commit(s)..."
                    git push origin main
                    success "Full sync complete!"
                fi
            fi
            ;;
        *)
            warn "Invalid option."
            ;;
    esac
}

manage_colab_cli() {
    local repo_dir="$1"
    cd "$repo_dir" || return
    
    if ! command -v colab &>/dev/null; then
        warn "'colab' CLI is not installed."
        info "To install the Google Colab CLI, please run:"
        info "  pip install google-colab-cli"
        info "or if you have 'uv' installed:"
        info "  uv tool install google-colab-cli"
        return
    fi
    
    while true; do
        echo -e "\n--- Colab CLI Operations for $(basename "$repo_dir") ---"
        echo "1) 🚀 Start/Provision a new Colab VM"
        echo "2) 📊 Check VM Session Status"
        echo "3) ⚡ Execute Notebook/Script remotely"
        echo "4) 🌐 Open Session in Browser"
        echo "5) 🛑 Stop/Terminate Colab VM"
        echo "6) 📥 Download files/logs from Colab VM"
        echo "7) 🔙 Go Back"
        read -p "Select option [1-7]: " colab_opt
        
        case $colab_opt in
            1)
                read -p "Enter session name [Default: 'ai-course']: " sname
                sname=${sname:-"ai-course"}
                echo "Select accelerator type:"
                echo "1) CPU"
                echo "2) T4 GPU"
                echo "3) L4 GPU"
                echo "4) A100 GPU"
                read -p "Select option [1-4, Default: 2]: " gpu_opt
                gpu_opt=${gpu_opt:-2}
                
                local gpu_flag=""
                case $gpu_opt in
                    1) gpu_flag="" ;;
                    2) gpu_flag="--gpu T4" ;;
                    3) gpu_flag="--gpu L4" ;;
                    4) gpu_flag="--gpu A100" ;;
                    *) gpu_flag="--gpu T4" ;;
                esac
                
                info "Provisioning Colab VM session '$sname'..."
                if [ -n "$gpu_flag" ]; then
                    colab new -s "$sname" $gpu_flag
                else
                    colab new -s "$sname"
                fi
                success "Session '$sname' provisioned successfully!"
                ;;
            2)
                info "Active Colab Sessions:"
                colab sessions || true
                echo -e "\nSession Status Detail:"
                colab status || true
                ;;
            3)
                # Find python/notebook files in the course directory
                info "Scanning for scripts and notebooks..."
                files=()
                while IFS= read -r -d $'\0' file; do
                    rel_file="${file#./}"
                    if [[ "$rel_file" != .git* ]] && [[ "$rel_file" != WORKFLOW_DOCS* ]] && [[ "$rel_file" != *venv* ]] && [[ "$rel_file" != *.env* ]]; then
                        files+=("$rel_file")
                    fi
                done < <(find . -type f \( -name "*.ipynb" -o -name "*.py" \) -print0 | sort -z)
                
                if [ ${#files[@]} -eq 0 ]; then
                    warn "No Python scripts or Jupyter Notebooks found."
                    continue
                fi
                
                echo "Available Notebooks/Scripts:"
                for i in "${!files[@]}"; do
                    echo "$((i+1))) ${files[$i]}"
                done
                read -p "Select file to execute [1-${#files[@]}]: " file_idx
                
                actual_file_idx=$((file_idx - 1))
                if [ $actual_file_idx -lt 0 ] || [ $actual_file_idx -ge ${#files[@]} ]; then
                    warn "Invalid file selection."
                    continue
                fi
                
                selected_file="${files[$actual_file_idx]}"
                read -p "Enter session name to use [Default: 'ai-course']: " sname
                sname=${sname:-"ai-course"}
                
                info "Executing '$selected_file' on Colab session '$sname'..."
                colab exec -s "$sname" -f "$selected_file"
                success "Execution complete!"
                ;;
            4)
                read -p "Enter session name to open [Default: 'ai-course']: " sname
                sname=${sname:-"ai-course"}
                info "Opening session '$sname' in browser..."
                colab url -s "$sname" --open || colab url -s "$sname"
                ;;
            5)
                read -p "Enter session name to stop [Default: 'ai-course']: " sname
                sname=${sname:-"ai-course"}
                warn "Terminating Colab VM session '$sname'..."
                colab stop -s "$sname"
                success "Session stopped."
                ;;
            6)
                read -p "Enter session name to download from [Default: 'ai-course']: " sname
                sname=${sname:-"ai-course"}
                read -p "Enter remote path on Colab VM (e.g. checkpoints/model.bin): " remote_path
                read -p "Enter local destination path [Default: '.']: " local_path
                local_path=${local_path:-"."}
                
                if [ -z "$remote_path" ]; then
                    warn "Remote path cannot be empty."
                    continue
                fi
                
                info "Downloading '$remote_path' from session '$sname' to '$local_path'..."
                colab download -s "$sname" "$remote_path" "$local_path"
                success "Download completed successfully!"
                ;;
            7)
                break
                ;;
            *)
                warn "Invalid selection."
                ;;
        esac
    done
}

update_from_upstream() {
    echo -e "\n--- Updating from Upstream (Official Repository) ---"
    # Find Git repositories
    repos=()
    while IFS= read -r -d $'\0' file; do
        repos+=("$(dirname "$file")")
    done < <(find "$HOME/learning" -name ".git" -type d -print0)

    if [ ${#repos[@]} -eq 0 ]; then
        warn "No learning repositories found."
        return
    fi

    echo "Select a course repository to update:"
    for i in "${!repos[@]}"; do
        echo "$((i+1))) $(basename "${repos[$i]}")"
    done
    read -p "Select course [1-${#repos[@]}]: " repo_idx

    actual_idx=$((repo_idx - 1))
    if [ $actual_idx -lt 0 ] || [ $actual_idx -ge ${#repos[@]} ]; then
        warn "Invalid selection."
        return
    fi

    repo_dir="${repos[$actual_idx]}"
    cd "$repo_dir" || return

    # Check if upstream exists
    if ! git remote | grep -q "upstream"; then
        read -p "No upstream remote configured. Enter upstream repo URL (e.g. microsoft/AI-For-Beginners): " upstream_url
        git remote add upstream "https://github.com/${upstream_url}.git"
    fi

    info "Fetching official changes from upstream..."
    git fetch upstream
    info "Merging updates into local main branch..."
    git merge upstream/main --no-edit
    
    # ✂️ Purge inherited Microsoft workflows again if they snuck back in
    if [ -d ".github/workflows" ]; then
        info "Purging inherited GitHub Actions to save free-tier minutes..."
        git rm -rf .github/workflows
        git commit -m "chore: purge inherited github actions after upstream merge" || true
    fi

    # Check if local is ahead of remote (origin/main)
    local local_ahead
    local_ahead=$(git rev-list --count origin/main..main 2>/dev/null || echo "0")
    if [ "$local_ahead" -eq 0 ]; then
        success "GitHub fork and local files are already up to date. No push needed!"
    else
        info "Pushing updates to your GitHub fork..."
        git push origin main
        success "Successfully updated fork and local files with official changes!"
    fi
}

self_update() {
    echo -e "\n--- Updating Automation Script ---"
    info "Fetching latest script from @saquib-byte's master repository..."
    
    local remote_url="https://raw.githubusercontent.com/saquib-byte/Deep-Learning-Fundamentals/main/WORKFLOW_DOCS/learning_helper.sh"
    local local_script="$HOME/learning/learning_helper.sh"
    
    if curl -s -f -o "${local_script}.tmp" "$remote_url"; then
        mv "${local_script}.tmp" "$local_script"
        chmod +x "$local_script"
        success "Script successfully updated!"
        info "Please restart the script to apply changes."
        exit 0
    else
        error "Failed to download update. Please check your internet connection or the repository URL."
        rm -f "${local_script}.tmp"
    fi
}

workspace_status() {
    echo -e "\n--- Workspace Status ---"
    # Find Git repositories
    repos=()
    while IFS= read -r -d $'\0' file; do
        repos+=("$(dirname "$file")")
    done < <(find "$HOME/learning" -name ".git" -type d -print0)

    if [ ${#repos[@]} -eq 0 ]; then
        warn "No learning repositories found."
        return
    fi

    echo "Select a course repository to check:"
    for i in "${!repos[@]}"; do
        echo "$((i+1))) $(basename "${repos[$i]}")"
    done
    read -p "Select course [1-${#repos[@]}]: " repo_idx

    actual_idx=$((repo_idx - 1))
    if [ $actual_idx -lt 0 ] || [ $actual_idx -ge ${#repos[@]} ]; then
        warn "Invalid selection."
        return
    fi

    repo_dir="${repos[$actual_idx]}"
    cd "$repo_dir" || return
    
    info "Status for: $(basename "$repo_dir")"
    
    if git remote | grep -q "^upstream$"; then
        git fetch upstream >/dev/null 2>&1 || true
        local behind
        behind=$(git rev-list --count main..upstream/main 2>/dev/null || echo "0")
        if [ "$behind" -gt 0 ]; then
            echo -e "${YELLOW}Notice: Microsoft's official curriculum has $behind new updates! Use Option 3 to sync them.${NC}"
        else
            echo -e "${GREEN}You are fully up to date with Microsoft's official curriculum.${NC}"
        fi
    fi
    
    git fetch origin main >/dev/null 2>&1 || true
    git status
    
    echo ""
    read -p "Would you like to check for updates to this automation script? (y/N): " check_update
    if [[ "$check_update" == "y" || "$check_update" == "Y" ]]; then
        self_update
    fi
}

# Main Execution Loop
while true; do
    show_menu
    read -r opt
    case $opt in
        1) setup_new_course ;;
        2) sync_menu ;;
        3) update_from_upstream ;;
        4) workspace_status ;;
        5) echo "Goodbye!"; read -p "Press Enter to close this terminal..." ; exit 0 ;;
        *) warn "Invalid selection. Please try again." ;;
    esac
done
