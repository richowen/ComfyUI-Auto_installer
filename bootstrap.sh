#!/usr/bin/env bash
set -euo pipefail

# Colors for output
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
NC='\033[0m'

# Default installation directory
DEFAULT_DIR="$HOME/comfyui-workspace"
INSTALL_DIR="$DEFAULT_DIR"

# Repository URL
REPO_URL="https://github.com/richowen/ComfyUI-Auto_installer.git"
BRANCH="main"

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --directory DIR    Installation directory (default: $DEFAULT_DIR)"
    echo "  -b, --branch BRANCH    Git branch to use (default: main)"
    echo "  -y, --yes              Non-interactive mode, answer yes to all prompts"
    echo "  -h, --help             Display this help message"
    exit 1
}

# Parse command line arguments
NONINTERACTIVE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -y|--yes)
            NONINTERACTIVE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to show spinner during long operations
show_spinner() {
    local message=$1
    shift
    local cmd=("$@")
    local delay=0.1
    local spinstr='|/-\'
    local i=0

    echo -n "$message "

    "${cmd[@]}" &
    local pid=$!

    while kill -0 $pid 2>/dev/null; do
        i=$(((i + 1) % 4))
        printf "\r$message [%c]" "${spinstr:$i:1}"
        sleep $delay
    done

    wait $pid 2>/dev/null
    local exit_code=$?

    printf "\r$message [✔] Done!%s\n" "$(printf '%*s' $((40 - ${#message})) '')"

    return $exit_code
}

# Function to print a step with a specific message
step() {
    echo -e "${BLUE}───[ $1 ]──────────────────────────────────────${NC}"
}

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}         ComfyUI - WAN2.1 - Ubuntu Installer         ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check if running as root and warn user
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Warning: You are running this script as root.${NC}"
    echo -e "${RED}It's recommended to run as a normal user with sudo privileges.${NC}"
    if [ "$NONINTERACTIVE" != true ]; then
        read -rp "Continue anyway? (y/N) " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
fi

# Check for Ubuntu/Debian
if ! command_exists apt-get; then
    echo -e "${RED}This script is designed for Ubuntu/Debian systems.${NC}"
    echo -e "${RED}Your system does not have apt-get. Script may not work as expected.${NC}"
    if [ "$NONINTERACTIVE" != true ]; then
        read -rp "Continue anyway? (y/N) " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
fi

# Check if NVIDIA GPU is available
if command_exists nvidia-smi; then
    echo -e "${GREEN}NVIDIA GPU detected.${NC}"
    nvidia-smi --query-gpu=name --format=csv,noheader
else
    echo -e "${RED}Warning: NVIDIA GPU not detected or driver not installed.${NC}"
    echo -e "${RED}ComfyUI requires an NVIDIA GPU for optimal performance.${NC}"
    if [ "$NONINTERACTIVE" != true ]; then
        read -rp "Continue anyway? (y/N) " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
fi

# Check for free disk space (need at least 20GB)
FREE_SPACE=$(df -BG --output=avail "$HOME" | tail -n 1 | tr -d 'G')
if [ "$FREE_SPACE" -lt 20 ]; then
    echo -e "${RED}Warning: Less than 20GB free disk space available.${NC}"
    echo -e "${RED}ComfyUI with models may require significant disk space.${NC}"
    if [ "$NONINTERACTIVE" != true ]; then
        read -rp "Continue anyway? (y/N) " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
fi

# Check and install required dependencies
step "Checking required dependencies..."
DEPS_TO_INSTALL=()

for dep in git curl wget p7zip-full python3-venv python3-full python3-dev build-essential cmake; do
    if ! command_exists "$dep" && ! dpkg -l | grep -q "$dep"; then
        DEPS_TO_INSTALL+=("$dep")
    fi
done

if [ ${#DEPS_TO_INSTALL[@]} -gt 0 ]; then
    step "Installing required dependencies"
    sudo apt-get update
    sudo apt-get install -y "${DEPS_TO_INSTALL[@]}"
fi

# Create and navigate to installation directory
step "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Check if ComfyUI-Auto_installer already exists
if [ -d "$INSTALL_DIR/ComfyUI-Auto_installer" ]; then
    step "ComfyUI-Auto_installer directory already exists."
    if [ "$NONINTERACTIVE" != true ]; then
        read -rp "Update existing repository? (Y/n) " response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            cd "$INSTALL_DIR/ComfyUI-Auto_installer"
            git fetch
            git reset --hard "origin/$BRANCH"
        fi
    else
        cd "$INSTALL_DIR/ComfyUI-Auto_installer"
        git fetch
        git reset --hard "origin/$BRANCH"
    fi
else
    # Clone repository
    step "Cloning ComfyUI-Auto_installer repository..."
    git clone --branch "$BRANCH" "$REPO_URL" ComfyUI-Auto_installer
    cd "$INSTALL_DIR/ComfyUI-Auto_installer"
fi

# Make scripts executable
step "Setting executable permissions..."
find . -name "*.sh" -type f -exec chmod +x {} \;

# Run the installer
step "Running installer"
./UmeAiRT-AllinOne-Auto_install.sh

# Final instructions
echo -e "${GREEN}Bootstrap complete!${NC}"
echo -e "${BLUE}You can now use ComfyUI with the following commands:${NC}"
echo "  cd $INSTALL_DIR"
echo "  ./run_comfyui.sh         - Standard mode"
echo "  ./run_comfyui_lowvram.sh - Low VRAM mode"
echo ""
echo -e "${BLUE}Visit http://localhost:8188 in your browser once ComfyUI is running.${NC}"
