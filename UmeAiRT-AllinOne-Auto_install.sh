#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW='\033[33m'
BLUE='\033[34m'
RED='\033[31m'
NC='\033[0m'

installPath="$(pwd)"
comfyPath="$installPath/ComfyUI"
customNodesPath="$comfyPath/custom_nodes"
modelsPath="$comfyPath/models"
logDir="$installPath/logs"
logFile="$logDir/install.txt"

mkdir -p "$logDir"

# Banner
curl -L -o banner.txt "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/banner.txt?download=true" >> "$logFile" 2>&1
echo "-------------------------------------------------------------------------------${BLUE}"
cat banner.txt
echo -e "${NC}-------------------------------------------------------------------------------"
echo "                    ComfyUI - WAN2.1 - All in one installer"
echo "                                                           V2.2 for CUDA 12.8"
echo "-------------------------------------------------------------------------------"
rm -f banner.txt

# Check for 7z
if ! command -v 7z &>/dev/null; then
    echo "7-Zip is not installed. Installing p7zip-full..."
    sudo apt-get update && sudo apt-get install -y p7zip-full
fi

# Check for git
if ! command -v git &>/dev/null; then
    echo "Git is not installed. Installing git..."
    sudo apt-get update && sudo apt-get install -y git
fi

echo -e "${YELLOW}Enabling long paths for git...${NC}"
git config --global core.longpaths true || true

show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='◐◓◑◒'  # Cute donut spinner
    local i=0
    local start_time=$(date +%s)

    tput civis  # Hide cursor
    echo -ne "\e[1;36m$message \e[0m"

    while kill -0 "$pid" 2>/dev/null; do
        local idx=$((i % ${#spinstr}))
        local ch="${spinstr:$idx:1}"
        local now=$(date +%s)
        local elapsed=$((now - start_time))

        printf "\r\e[1;36m$message \e[0m[%s] \e[2m(%ds)\e[0m" "$ch" "$elapsed"
        sleep "$delay"
        i=$((i + 1))
    done

    local total_time=$(( $(date +%s) - start_time ))
    printf "\r\e[1;32m$message done! (%ds)\e[0m\n" "$total_time"
    tput cnorm  # Restore cursor
}


# Clone ComfyUI directly from GitHub
echo -e "${YELLOW}Cloning ComfyUI from GitHub...${NC}"
git clone https://github.com/comfyanonymous/ComfyUI.git "$comfyPath" >> "$logFile" 2>&1 &
show_spinner $! "Cloning repository..."

# Set up Python virtual environment
echo -e "${YELLOW}Installing Python venv support...${NC}"
sudo apt-get update && sudo apt-get install -y python3-venv python3-full >> "$logFile" 2>&1 &
show_spinner $! "Installing Python venv packages..."

echo -e "${YELLOW}Creating virtual environment...${NC}"
python3 -m venv "$installPath/comfyui_venv" >> "$logFile" 2>&1 &
show_spinner $! "Creating virtual environment..."

echo -e "${YELLOW}Upgrading pip in virtual environment...${NC}"
"$installPath/comfyui_venv/bin/python" -m pip install --upgrade pip >> "$logFile" 2>&1 &
show_spinner $! "Upgrading pip..."

# Use the virtual environment's Python and pip
PYTHON="$installPath/comfyui_venv/bin/python"
PIP="$installPath/comfyui_venv/bin/pip"

# Upgrade pip and install requirements
echo -e "${YELLOW}Installing requirements...${NC}"
$PIP install -r "$comfyPath/requirements.txt" >> "$logFile" 2>&1 &
show_spinner $! "Installing Python requirements... (this may take a while)"

# Clone and install custom nodes
echo -e "${YELLOW}Installing ComfyUI-Manager...${NC}"
git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$customNodesPath/ComfyUI-Manager" >> "$logFile" 2>&1 &
show_spinner $! "Installing ComfyUI-Manager..."

echo -e "${YELLOW}Installing additional nodes...${NC}"

declare -A repos=(
    ["ComfyUI-Impact-Pack"]="https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    ["ComfyUI-Impact-Pack/impact_subpack"]="https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
    ["ComfyUI-GGUF"]="https://github.com/city96/ComfyUI-GGUF"
    ["ComfyUI-mxToolkit"]="https://github.com/Smirnov75/ComfyUI-mxToolkit"
    ["ComfyUI-Custom-Scripts"]="https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    ["ComfyUI-KJNodes"]="https://github.com/kijai/ComfyUI-KJNodes"
    ["ComfyUI-WanVideoWrapper"]="https://github.com/kijai/ComfyUI-WanVideoWrapper"
    ["ComfyUI-VideoHelperSuite"]="https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    ["ComfyUI-Frame-Interpolation"]="https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
    ["rgthree-comfy"]="https://github.com/rgthree/rgthree-comfy"
    ["ComfyUI-Easy-Use"]="https://github.com/yolain/ComfyUI-Easy-Use"
    ["ComfyUI_PuLID_Flux_ll"]="https://github.com/lldacing/ComfyUI_PuLID_Flux_ll"
    ["ComfyUI-HunyuanVideoMultiLora"]="https://github.com/facok/ComfyUI-HunyuanVideoMultiLora"
    ["was-node-suite-comfyui"]="https://github.com/WASasquatch/was-node-suite-comfyui"
    ["ComfyUI-Florence2"]="https://github.com/kijai/ComfyUI-Florence2"
    ["ComfyUI-Upscaler-Tensorrt"]="https://github.com/yuvraj108c/ComfyUI-Upscaler-Tensorrt"
    ["ComfyUI-WanStartEndFramesNative"]="https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative"
    ["ComfyUI-Image-Saver"]="https://github.com/alexopus/ComfyUI-Image-Saver"
    ["ComfyUI_UltimateSDUpscale"]="https://github.com/ssitu/ComfyUI_UltimateSDUpscale"
)

# Function to track total progress
total_repos=${#repos[@]}
current_repo=0

for repo in "${!repos[@]}"; do
    current_repo=$((current_repo+1))
    echo -e "  - $repo ($current_repo of $total_repos)"
    
    git clone "${repos[$repo]}" "$customNodesPath/$repo" >> "$logFile" 2>&1 &
    show_spinner $! "  Cloning repository..."
    
    if [ -f "$customNodesPath/$repo/requirements.txt" ]; then
        $PIP install -r "$customNodesPath/$repo/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1 &
        show_spinner $! "  Installing requirements..."
    fi
done

# Special requirements for some nodes
echo -e "${YELLOW}Installing special requirements...${NC}"
if [ -f "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack/requirements.txt" ]; then
    $PIP install -r "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1 &
    show_spinner $! "Installing Impact-Pack subpack requirements..."
fi
if [ -f "$customNodesPath/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt" ]; then
    $PIP install -r "$customNodesPath/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt" --no-warn-script-location >> "$logFile" 2>&1 &
    show_spinner $! "Installing Frame-Interpolation requirements..."
fi

# Additional pip installs
echo -e "${YELLOW}Installing additional packages...${NC}"
$PIP install ultralytics --no-warn-script-location >> "$logFile" 2>&1 &
show_spinner $! "Installing ultralytics..."

$PIP install transformers==4.49.0 --upgrade >> "$logFile" 2>&1 &
show_spinner $! "Installing transformers..."

$PIP install wheel-stub >> "$logFile" 2>&1 &
show_spinner $! "Installing wheel-stub..."

# Download comfy settings and workflow
mkdir -p "$comfyPath/user/default/workflows"
echo -e "${YELLOW}Downloading comfy settings...${NC}"
curl -L -o "$comfyPath/user/default/comfy.settings.json" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/comfy.settings.json?download=true" >> "$logFile" 2>&1 &
show_spinner $! "Downloading settings file..."

echo -e "${YELLOW}Downloading comfy workflow...${NC}"
curl -L -o "$comfyPath/user/default/workflows/UmeAiRT-WAN21_workflow.7z" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/workflows/UmeAiRT-WAN21_workflow.7z?download=true" >> "$logFile" 2>&1 &
show_spinner $! "Downloading workflow archive..."

echo -e "${YELLOW}Extracting workflow files...${NC}"
7z x "$comfyPath/user/default/workflows/UmeAiRT-WAN21_workflow.7z" -o"$comfyPath/user/default/workflows/" -y >> "$logFile" 2>&1 &
show_spinner $! "Extracting files..."

rm -f "$comfyPath/user/default/workflows/UmeAiRT-WAN21_workflow.7z"


# User prompt for WAN models
while true; do
    echo -e "${YELLOW}Would you like to download WAN models?${NC}"
    read -rp "Enter your choice (Y or N) and press Enter: " MODELS
    case "$MODELS" in
        [Yy]* )
            # Use local converted script
            bash "$installPath/UmeAiRT-WAN2.1-Model_downloader.sh"
            break
            ;;
        [Nn]* )
            break
            ;;
        * )
            echo -e "${RED}Invalid choice. Please enter Y or N.${NC}"
            ;;
    esac
done

# User prompt for LoRA models
while true; do
    echo -e "${YELLOW}Would you like to download custom LoRA models?${NC}"
    read -rp "Enter your choice (Y or N) and press Enter: " LORA_CHOICE
    case "$LORA_CHOICE" in
        [Yy]* )
            # Make the script executable
            chmod +x "$installPath/UmeAiRT-LoRA_downloader.sh"
            # Run the LoRA downloader
            bash "$installPath/UmeAiRT-LoRA_downloader.sh"
            break
            ;;
        [Nn]* )
            break
            ;;
        * )
            echo -e "${RED}Invalid choice. Please enter Y or N.${NC}"
            ;;
    esac
done

echo -e "${YELLOW}Installation completed successfully!${NC}"
echo ""
echo -e "${BLUE}To start ComfyUI, run either:${NC}"
echo "  ./run_comfyui.sh         - Standard mode"
echo "  ./run_comfyui_lowvram.sh - Low VRAM mode"
echo ""
echo -e "${BLUE}Once started, open your browser and navigate to:${NC}"
echo "  http://localhost:8188"
echo ""
