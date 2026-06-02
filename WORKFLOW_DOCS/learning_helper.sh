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
    echo -e "2) 🔄 Sync Local <-> GitHub Fork (Pull/Push)"
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
    # ⚡ Inject @saquib-byte signature to the bottom of the cloned SETUP_GUIDE
    echo -e "\n---\n*⚡ Setup fully automated & optimized using the [Learning Environment Helper](https://github.com/saquib-byte/Deep-Learning-Fundamentals) created by [@saquib-byte](https://github.com/saquib-byte).*" >> SETUP_GUIDE.md

    # Commit the signature to their new fork immediately
    info "Saving automation signature to repository..."
    git add SETUP_GUIDE.md
    git commit -m "Initialize workspace with @saquib-byte's automation tools"
    git push origin main
    
    echo -e "\n============================================="
    success "Setup complete!"
    info "Your new learning environment is located at:"
    echo -e "${YELLOW}  $target_dir ${NC}"
    echo -e "=============================================\n"

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
    echo -e "\n--- Syncing Courses ---"
    # Find all Git repositories in ~/learning
    repos=()
    while IFS= read -r -d $'\0' file; do
        repos+=("$(dirname "$file")")
    done < <(find "$HOME/learning" -name ".git" -type d -print0)

    if [ ${#repos[@]} -eq 0 ]; then
        warn "No learning repositories found."
        return
    fi

    echo "Select a course repository to sync:"
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
    cd "$repo_dir" || return

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
            info "Staging changes..."
            git add .
            read -p "Enter commit message [Default: 'Update practice notebooks']: " msg
            if [ -z "$msg" ]; then msg="Update practice notebooks"; fi
            git commit -m "$msg"
            info "Pushing changes..."
            git push origin main
            success "Pushed to GitHub fork!"
            ;;
        3)
            info "Pulling updates from GitHub..."
            git pull origin main
            info "Staging changes..."
            git add .
            read -p "Enter commit message [Default: 'Update practice notebooks']: " msg
            if [ -z "$msg" ]; then msg="Update practice notebooks"; fi
            git commit -m "$msg"
            info "Pushing changes..."
            git push origin main
            success "Full sync complete!"
            ;;
        *)
            warn "Invalid option."
            ;;
    esac
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
    info "Pushing updates to your GitHub fork..."
    git push origin main
    success "Successfully updated fork and local files with official changes!"
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
    git fetch origin main >/dev/null 2>&1 || true
    git status
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
