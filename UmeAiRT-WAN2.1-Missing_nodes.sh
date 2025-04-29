#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
NC='\033[0m'

installPath="$(pwd)"
comfyPath="$installPath/ComfyUI"
customNodesPath="$comfyPath/custom_nodes"

mkdir -p "$installPath/logs"
logFile="$installPath/logs/Missing_nodes.txt"

# Check if ComfyUI folder exists
if [ -d "$installPath/ComfyUI" ]; then
    echo "ComfyUI folder detected"
    comfyPath="$installPath/ComfyUI"
else
    echo "ComfyUI folder not detected, please run the main installer first."
    read -rp "Press Enter to exit..."
    exit 1
fi

customNodesPath="$comfyPath/custom_nodes"

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


# Ensure we have venv support
echo -e "${YELLOW}Ensuring Python venv support is installed...${NC}"
sudo apt-get update && sudo apt-get install -y python3-venv python3-full >> "$logFile" 2>&1 &
show_spinner $! "Installing Python venv packages..."

# Define the Python executable from virtual environment
if [ -d "$installPath/comfyui_venv" ]; then
    echo "Using Python virtual environment"
    PYTHON="$installPath/comfyui_venv/bin/python"
    PIP="$installPath/comfyui_venv/bin/pip"
else
    echo "Virtual environment not found, creating one"
    python3 -m venv "$installPath/comfyui_venv" >> "$logFile" 2>&1 &
    show_spinner $! "Creating virtual environment..."
    
    PYTHON="$installPath/comfyui_venv/bin/python"
    PIP="$installPath/comfyui_venv/bin/pip"
    
    echo "Upgrading pip..."
    "$PIP" install --upgrade pip >> "$logFile" 2>&1 &
    show_spinner $! "Upgrading pip in virtual environment..."
fi

# Update ComfyUI
echo -e "${YELLOW}Update ComfyUI${NC}"
git -C "$comfyPath" pull >> "$logFile" 2>&1 &
show_spinner $! "Pulling latest ComfyUI changes..."

echo "Installing ComfyUI requirements..."
"$PIP" install -r "$comfyPath/requirements.txt" >> "$logFile" 2>&1 &
show_spinner $! "Installing ComfyUI requirements..."

# Ask user if they want to do a clean install
while true; do
    echo -e "${YELLOW}Do you want to do a clean install? (all currently present custom nodes are deleted)${NC}"
    echo -e "${GREEN}A) Yes${NC}"
    echo -e "${GREEN}B) No${NC}"
    read -rp "Enter your choice (A or B) and press Enter: " CHOOSE_CLEAN
    
    case "$CHOOSE_CLEAN" in
        [Aa])
            # Clean install - remove all custom nodes
            rm -rf "$customNodesPath"/* >> "$logFile" 2>&1
            break
            ;;
        [Bb])
            CHOOSE_CLEANL="no"
            break
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter A or B.${NC}"
            ;;
    esac
done

# Create customNodesPath if it doesn't exist
mkdir -p "$customNodesPath"

# Clone ComfyUI-Manager
echo -e "${YELLOW}Installing ComfyUI-Manager...${NC}"
git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$customNodesPath/ComfyUI-Manager" >> "$logFile" 2>&1 &
show_spinner $! "Cloning ComfyUI-Manager repository..."

echo -e "${YELLOW}Installing additional nodes...${NC}"

# Install Impact-Pack
echo "  - Impact-Pack"
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack "$customNodesPath/ComfyUI-Impact-Pack" >> "$logFile" 2>&1 &
show_spinner $! "Cloning Impact-Pack..."

"$PIP" install -r "$customNodesPath/ComfyUI-Impact-Pack/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1 &
show_spinner $! "Installing Impact-Pack requirements..."

git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack" >> "$logFile" 2>&1 &
show_spinner $! "Cloning Impact-Subpack..."

"$PIP" install -r "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1 &
show_spinner $! "Installing Impact-Subpack requirements..."

"$PIP" install ultralytics --no-warn-script-location >> "$logFile" 2>&1 &
show_spinner $! "Installing ultralytics..."

echo "  - GGUF"
git clone https://github.com/city96/ComfyUI-GGUF "$customNodesPath/ComfyUI-GGUF" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-GGUF/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - mxToolkit"
git clone https://github.com/Smirnov75/ComfyUI-mxToolkit "$customNodesPath/ComfyUI-mxToolkit" >> "$logFile" 2>&1

echo "  - Custom-Scripts"
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts "$customNodesPath/ComfyUI-Custom-Scripts" >> "$logFile" 2>&1

echo "  - KJNodes"
git clone https://github.com/kijai/ComfyUI-KJNodes "$customNodesPath/ComfyUI-KJNodes" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-KJNodes/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - VideoHelperSuite"
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite "$customNodesPath/ComfyUI-VideoHelperSuite" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-VideoHelperSuite/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - Frame-Interpolation"
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation "$customNodesPath/ComfyUI-Frame-Interpolation" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - rgthree"
git clone https://github.com/rgthree/rgthree-comfy "$customNodesPath/rgthree-comfy" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/rgthree-comfy/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - Easy-Use"
git clone https://github.com/yolain/ComfyUI-Easy-Use "$customNodesPath/ComfyUI-Easy-Use" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-Easy-Use/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - PuLID_Flux_ll"
git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll "$customNodesPath/ComfyUI_PuLID_Flux_ll" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI_PuLID_Flux_ll/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

# For Ubuntu, use pip to install facexlib and filterpy directly
"$PIP" install --use-pep517 facexlib >> "$logFile" 2>&1
"$PIP" install git+https://github.com/rodjjo/filterpy.git >> "$logFile" 2>&1
"$PIP" install onnxruntime==1.19.2 onnxruntime-gpu==1.15.1 >> "$logFile" 2>&1

echo "  - HunyuanVideoMultiLora"
git clone https://github.com/facok/ComfyUI-HunyuanVideoMultiLora "$customNodesPath/ComfyUI-HunyuanVideoMultiLora" >> "$logFile" 2>&1

echo "  - was-node-suite-comfyui"
git clone https://github.com/WASasquatch/was-node-suite-comfyui "$customNodesPath/was-node-suite-comfyui" >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/was-node-suite-comfyui/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - Florence2"
git clone https://github.com/kijai/ComfyUI-Florence2 "$customNodesPath/ComfyUI-Florence2" >> "$logFile" 2>&1
"$PIP" install transformers==4.49.0 --upgrade >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-Florence2/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - Upscaler-Tensorrt"
git clone https://github.com/yuvraj108c/ComfyUI-Upscaler-Tensorrt "$customNodesPath/ComfyUI-Upscaler-Tensorrt" >> "$logFile" 2>&1
"$PIP" install wheel-stub >> "$logFile" 2>&1
"$PIP" install -r "$customNodesPath/ComfyUI-Upscaler-Tensorrt/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1

echo "  - MultiGPU"
git clone https://github.com/pollockjj/ComfyUI-MultiGPU "$customNodesPath/ComfyUI-MultiGPU" >> "$logFile" 2>&1

echo "  - WanStartEndFramesNative"
git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative "$customNodesPath/ComfyUI-WanStartEndFramesNative" >> "$logFile" 2>&1

# WAN specific nodes
echo "  - WanVideoWrapper"
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper "$customNodesPath/ComfyUI-WanVideoWrapper" >> "$logFile" 2>&1 &
show_spinner $! "Cloning WanVideoWrapper..."

echo -e "${YELLOW}Installation complete${NC}"
read -rp "Press Enter to continue..."
