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

# Function to install requirements and run install.py
install_node_requirements() {
    local node_path="$1"
    local node_name="$2"
    local indent="$3"
    
    # Check for and install requirements.txt
    if [ -f "$node_path/requirements.txt" ]; then
        $PIP install -r "$node_path/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1 &
        show_spinner $! "${indent}Installing $node_name requirements..."
    fi
    
    # Check for and run install.py
    if [ -f "$node_path/install.py" ]; then
        echo -e "${indent}Found $node_name install.py script, running it..."
        $PYTHON "$node_path/install.py" >> "$logFile" 2>&1 &
        show_spinner $! "${indent}Running $node_name install.py script..."
    fi
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

# Install additional packages
echo -e "${YELLOW}Installing additional packages...${NC}"
$PIP install wheel-stub >> "$logFile" 2>&1 &
show_spinner $! "Installing wheel-stub..."

$PIP install ultralytics --no-warn-script-location >> "$logFile" 2>&1 &
show_spinner $! "Installing ultralytics..."

$PIP install transformers==4.49.0 --upgrade >> "$logFile" 2>&1 &
show_spinner $! "Installing transformers..."

# Install onnx and insightface dependencies
echo -e "${YELLOW}Installing onnx runtime and insightface dependencies...${NC}"
$PIP install onnxruntime==1.19.2 onnxruntime-gpu==1.17.1 >> "$logFile" 2>&1 &
show_spinner $! "Installing onnxruntime..."

# Download appropriate insightface wheel based on Python version
echo -e "${YELLOW}Checking Python version for appropriate insightface wheel...${NC}"
PYTHON_VERSION=$($PYTHON --version | cut -d' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

echo -e "${YELLOW}Using Python $PYTHON_MAJOR.$PYTHON_MINOR - Installing appropriate insightface...${NC}"
if [ "$PYTHON_MINOR" -eq 10 ]; then
    curl -L -o "insightface-0.7.3-cp310-cp310-linux_x86_64.whl" "https://files.pythonhosted.org/packages/0f/89/7c3e30dd5ee0de0a78882214e7ce8079de6c7b8e90f01a44b880b38df257/insightface-0.7.3-cp310-cp310-linux_x86_64.whl" >> "$logFile" 2>&1 &
    show_spinner $! "Downloading insightface for Python 3.10..."
    $PIP install insightface-0.7.3-cp310-cp310-linux_x86_64.whl >> "$logFile" 2>&1 &
    show_spinner $! "Installing insightface for Python 3.10..."
    rm -f insightface-0.7.3-cp310-cp310-linux_x86_64.whl
elif [ "$PYTHON_MINOR" -eq 11 ]; then
    curl -L -o "insightface-0.7.3-cp311-cp311-linux_x86_64.whl" "https://files.pythonhosted.org/packages/6b/99/8c29f3ca04be3b22ce8c5a5ba4f9c38f21c2c5768f3d02e0c40aa04d4f9b/insightface-0.7.3-cp311-cp311-linux_x86_64.whl" >> "$logFile" 2>&1 &
    show_spinner $! "Downloading insightface for Python 3.11..."
    $PIP install insightface-0.7.3-cp311-cp311-linux_x86_64.whl >> "$logFile" 2>&1 &
    show_spinner $! "Installing insightface for Python 3.11..."
    rm -f insightface-0.7.3-cp311-cp311-linux_x86_64.whl
else
    # Use pip to install insightface if no specific wheel
    $PIP install insightface==0.7.3 >> "$logFile" 2>&1 &
    show_spinner $! "Installing insightface from PyPI..."
fi

# Install facexlib and filterpy
$PIP install --use-pep517 facexlib >> "$logFile" 2>&1 &
show_spinner $! "Installing facexlib..."

$PIP install git+https://github.com/rodjjo/filterpy.git >> "$logFile" 2>&1 &
show_spinner $! "Installing filterpy..."

# Install optimization packages for WAN models
echo -e "${YELLOW}Installing optimization packages for WAN model acceleration...${NC}"
$PIP install sageattention >> "$logFile" 2>&1 &
show_spinner $! "Installing sageattention..."

$PIP install triton >> "$logFile" 2>&1 &
show_spinner $! "Installing triton..."

$PIP install xformers >> "$logFile" 2>&1 &
show_spinner $! "Installing xformers..."

# NOW install custom nodes AFTER all dependencies
echo -e "${YELLOW}Installing ComfyUI-Manager...${NC}"
git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$customNodesPath/ComfyUI-Manager" >> "$logFile" 2>&1 &
show_spinner $! "Installing ComfyUI-Manager..."

echo -e "${YELLOW}Installing additional nodes...${NC}"

declare -A repos=(
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
    ["ComfyUI-MultiGPU"]="https://github.com/pollockjj/ComfyUI-MultiGPU"
)

# Clone and install nodes
total_repos=${#repos[@]}
current_repo=0

for repo in "${!repos[@]}"; do
    current_repo=$((current_repo+1))
    echo -e "  - $repo ($current_repo of $total_repos)"
    
    git clone "${repos[$repo]}" "$customNodesPath/$repo" >> "$logFile" 2>&1 &
    show_spinner $! "  Cloning repository..."
    
    # Install requirements and run install.py
    install_node_requirements "$customNodesPath/$repo" "$repo" "  "
done

# Special requirements for some nodes
echo -e "${YELLOW}Installing special requirements...${NC}"

# Special case for Impact-Pack subpack
if [ -f "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack/requirements.txt" ]; then
    $PIP install -r "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack/requirements.txt" --no-warn-script-location >> "$logFile" 2>&1 &
    show_spinner $! "Installing Impact-Pack subpack requirements..."
fi
install_node_requirements "$customNodesPath/ComfyUI-Impact-Pack/impact_subpack" "Impact-Pack subpack" ""

# Special case for Frame-Interpolation with cupy
if [ -f "$customNodesPath/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt" ]; then
    $PIP install -r "$customNodesPath/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt" --no-warn-script-location >> "$logFile" 2>&1 &
    show_spinner $! "Installing Frame-Interpolation requirements..."
fi
install_node_requirements "$customNodesPath/ComfyUI-Frame-Interpolation" "Frame-Interpolation" ""

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

# Create run scripts
echo -e "${YELLOW}Creating run scripts...${NC}"

# Create standard run script
cat > "$installPath/run_comfyui.sh" << EOL
#!/usr/bin/env bash
source "$installPath/comfyui_venv/bin/activate"
cd "$installPath/ComfyUI"
python main.py 
EOL
chmod +x "$installPath/run_comfyui.sh"

# Create sageattention run script
mkdir -p "$installPath/scripts"
cat > "$installPath/scripts/run_nvidia_gpu-sageattention.sh" << EOL
#!/usr/bin/env bash
source "$installPath/comfyui_venv/bin/activate"
cd "$installPath/ComfyUI"
python main.py --use-sage-attention
EOL
chmod +x "$installPath/scripts/run_nvidia_gpu-sageattention.sh"

# Create low VRAM run script
cat > "$installPath/run_comfyui_lowvram.sh" << EOL
#!/usr/bin/env bash
source "$installPath/comfyui_venv/bin/activate"
cd "$installPath/ComfyUI"
python main.py --lowvram
EOL
chmod +x "$installPath/run_comfyui_lowvram.sh"

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
echo "  ./run_comfyui.sh                      - Standard mode"
echo "  ./run_comfyui_lowvram.sh              - Low VRAM mode"
echo "  ./scripts/run_nvidia_gpu-sageattention.sh - SageAttention mode (better performance)"
echo ""
echo -e "${BLUE}Once started, open your browser and navigate to:${NC}"
echo "  http://localhost:8188"
echo ""
