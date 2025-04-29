#!/usr/bin/env bash
set -euo pipefail

# ──[ Colors ]────────────────────────────────────────
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# ──[ Logging Helpers ]──────────────────────────────
step()    { echo -e "\n${BLUE}==> $*${NC}"; }
info()    { echo -e "   ${CYAN}$*${NC}"; }
warn()    { echo -e "   ${YELLOW}⚠ $*${NC}"; }
error()   { echo -e "${RED}✖ $*${NC}"; }
success() { echo -e "${GREEN}✔ $*${NC}"; }

# ──[ Cute Spinner ]──────────────────────────────────
show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='◐◓◑◒'
    local i=0
    local start_time=$(date +%s)

    tput civis
    echo -ne "${CYAN}${message} ${NC}"

    while kill -0 "$pid" 2>/dev/null; do
        local idx=$((i % ${#spinstr}))
        local ch="${spinstr:$idx:1}"
        local now=$(date +%s)
        local elapsed=$((now - start_time))
        printf "\r${CYAN}${message} ${NC}[%s] (%ds)" "$ch" "$elapsed"
        sleep "$delay"
        i=$((i + 1))
    done

    local total_time=$(( $(date +%s) - start_time ))
    printf "\r${GREEN}${message} done! (%ds)${NC}\n" "$total_time"
    tput cnorm
}

# ──[ Defaults & Globals ]────────────────────────────
DEFAULT_DIR="$HOME/comfyui-workspace"
INSTALL_DIR="$DEFAULT_DIR"
REPO_URL="https://github.com/richowen/ComfyUI-Auto_installer.git"
BRANCH="main"
NONINTERACTIVE=false

# ──[ CLI Argument Parsing ]──────────────────────────
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --directory DIR    Installation directory (default: $DEFAULT_DIR)"
    echo "  -b, --branch BRANCH    Git branch to use (default: main)"
    echo "  -y, --yes              Non-interactive mode, answer yes to all prompts"
    echo "  -h, --help             Display this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory) INSTALL_DIR="$2"; shift 2;;
        -b|--branch)    BRANCH="$2"; shift 2;;
        -y|--yes)       NONINTERACTIVE=true; shift;;
        -h|--help)      usage;;
        *) error "Unknown option: $1"; usage;;
    esac
done

# ──[ Utility Functions ]─────────────────────────────
command_exists() { command -v "$1" &>/dev/null; }
confirm_or_exit() {
    if [ "$NONINTERACTIVE" = true ]; then return; fi
    read -rp "$1 (y/N) " response
    [[ "$response" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}

# ──[ Welcome Banner ]────────────────────────────────
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}         ComfyUI - WAN2.1 - Ubuntu Installer         ${NC}"
echo -e "${BLUE}======================================================${NC}"

# ──[ Root Check ]────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
    warn "You are running this script as root."
    warn "It's recommended to run as a normal user with sudo."
    confirm_or_exit "Continue anyway?"
fi

# ──[ OS Compatibility Check ]────────────────────────
if ! command_exists apt-get; then
    error "This script is intended for Ubuntu/Debian systems."
    confirm_or_exit "Continue anyway?"
fi

# ──[ GPU Detection ]─────────────────────────────────
if command_exists nvidia-smi; then
    success "NVIDIA GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
else
    warn "NVIDIA GPU not detected. ComfyUI may not function optimally."
    confirm_or_exit "Continue anyway?"
fi

# ──[ Disk Space Check ]──────────────────────────────
FREE_SPACE=$(df -BG --output=avail "$HOME" | tail -n 1 | tr -d 'G')
if [ "$FREE_SPACE" -lt 20 ]; then
    warn "Less than 20GB free disk space."
    confirm_or_exit "Continue anyway?"
fi

# ──[ Dependency Check ]──────────────────────────────
step "Checking required dependencies"
DEPS_TO_INSTALL=()
for dep in git curl wget p7zip-full python3-venv python3-full python3-dev build-essential cmake; do
    if ! command_exists "$dep" && ! dpkg -l | grep -q "$dep"; then
        DEPS_TO_INSTALL+=("$dep")
    fi
done

if [ ${#DEPS_TO_INSTALL[@]} -gt 0 ]; then
    info "Installing: ${DEPS_TO_INSTALL[*]}"
    (sudo apt-get update && sudo apt-get install -y "${DEPS_TO_INSTALL[@]}") &
    show_spinner $! "Installing dependencies"
else
    success "All dependencies are satisfied."
fi

# ──[ Directory Setup ]───────────────────────────────
step "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# ──[ Clone or Update Repository ]────────────────────
if [ -d "ComfyUI-Auto_installer" ]; then
    step "Repository already exists."
    if [ "$NONINTERACTIVE" != true ]; then
        read -rp "Update existing repository? (Y/n) " response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            (cd ComfyUI-Auto_installer && git fetch && git reset --hard "origin/$BRANCH")
        fi
    else
        (cd ComfyUI-Auto_installer && git fetch && git reset --hard "origin/$BRANCH")
    fi
else
    step "Cloning repository"
    (git clone --branch "$BRANCH" "$REPO_URL" ComfyUI-Auto_installer) &
    show_spinner $! "Cloning ComfyUI-Auto_installer"
fi

cd ComfyUI-Auto_installer

# ──[ Permissions & Install ]─────────────────────────
step "Setting executable permissions"
find . -name "*.sh" -type f -exec chmod +x {} \;

step "Running installer"
(./UmeAiRT-AllinOne-Auto_install.sh) &
show_spinner $! "Installing ComfyUI environment"

# ──[ Finish ]────────────────────────────────────────
success "Bootstrap complete!"
echo -e "\n${BLUE}You can now use ComfyUI with:${NC}"
echo "  cd $INSTALL_DIR"
echo "  ./run_comfyui.sh         - Standard mode"
echo "  ./run_comfyui_lowvram.sh - Low VRAM mode"
echo -e "\n${BLUE}Open http://localhost:8188 in your browser once it's running.${NC}"