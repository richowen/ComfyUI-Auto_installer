#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
NC='\033[0m'

installPath="$(pwd)"
comfyPath="$installPath/ComfyUI"
customNodesPath="$comfyPath/custom_nodes"

mkdir -p "$installPath/logs"
logFile="$installPath/logs/SageAttention.txt"

# Display banner
curl -L -o banner.txt "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/banner.txt?download=true" >> "$logFile" 2>&1
echo "-------------------------------------------------------------------------------${BLUE}"
cat banner.txt
echo -e "${NC}-------------------------------------------------------------------------------"
echo "                  ComfyUI - WAN2.1 - SageAttention installer"
echo "                                                                     V1.3"
echo "-------------------------------------------------------------------------------"
rm -f banner.txt

# Check folders
if [ -d "$installPath/ComfyUI" ]; then
    echo "ComfyUI folder detected"
    comfyPath="$installPath/ComfyUI"
else
    echo "ComfyUI folder not detected, please run the main installer first."
    read -rp "Press Enter to exit..."
    exit 1
fi

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

# Ask user if they want to do a clean install
while true; do
    echo -e "${YELLOW}Do you want to do a clean install? (old triton and sageattention will be deleted)${NC}"
    echo -e "${GREEN}A) Yes${NC}"
    echo -e "${GREEN}B) No${NC}"
    read -rp "Enter your choice (A or B) and press Enter: " CHOOSE_CLEAN
    
    case "$CHOOSE_CLEAN" in
        [Aa])
            echo -e "${YELLOW}Uninstalling Triton and SageAttention...${NC}"
            "$PIP" uninstall -y triton-windows >> "$logFile" 2>&1 || true
            "$PIP" uninstall -y triton >> "$logFile" 2>&1 || true
            "$PIP" uninstall -y sageattention >> "$logFile" 2>&1 || true
            
            echo -e "${YELLOW}Removing SageAttention build files...${NC}"
            rm -rf "SageAttention" >> "$logFile" 2>&1 || true
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

# Install required build tools for Ubuntu
echo -e "${YELLOW}Installing build tools...${NC}"
sudo apt-get update && sudo apt-get install -y build-essential cmake python3-dev python3-venv python3-full >> "$logFile" 2>&1 &
show_spinner $! "Installing build tools..."

# Install CUDA development package if needed
echo -e "${YELLOW}Checking for CUDA...${NC}"
if ! dpkg -l | grep -q "cuda-toolkit"; then
    echo -e "${YELLOW}CUDA toolkit not found. SageAttention requires CUDA for optimal performance.${NC}"
    echo -e "${YELLOW}Please install CUDA toolkit manually if you haven't already.${NC}"
    echo -e "${YELLOW}Example: sudo apt install nvidia-cuda-toolkit${NC}"
    read -rp "Press Enter to continue..."
fi

# Install Triton
echo -e "${YELLOW}Installing Triton...${NC}"
"$PIP" install triton >> "$logFile" 2>&1 &
pid=$!
show_spinner $pid "Installing Triton (this may take a while)..."
if ! wait $pid; then
    echo "Triton installation might be partial, continuing..."
fi

# Download and install SageAttention
echo -e "${YELLOW}Downloading SageAttention...${NC}"
git clone https://github.com/thu-ml/SageAttention.git >> "$logFile" 2>&1 &
show_spinner $! "Cloning SageAttention repository..."

echo -e "${YELLOW}Installing SageAttention...${NC}"
"$PIP" install -e SageAttention >> "$logFile" 2>&1 &
pid=$!
show_spinner $pid "Installing SageAttention (this may take a while)..."
if ! wait $pid; then
    echo -e "${RED}SageAttention installation had issues. You may need to install it manually.${NC}"
    echo -e "${YELLOW}See log file at $logFile for details.${NC}"
fi

# Clean up
rm -rf "SageAttention" >> "$logFile" 2>&1 || true

# Create run script with SageAttention
echo -e "${YELLOW}Creating run script with SageAttention...${NC}"
cat > "$installPath/scripts/run_comfyui_sageattention.sh" << EOL
#!/usr/bin/env bash
source "$(dirname "\$0")/comfyui_venv/bin/activate"
cd "$(dirname "\$0")/ComfyUI"
python main.py --use-pytorch-cross-attention --use-xformers --use-sageattention
EOL
chmod +x "$installPath/scripts/run_comfyui_sageattention.sh"

echo -e "${YELLOW}Installation complete${NC}"
echo -e "${GREEN}To use SageAttention, run the script:${NC} ./run_comfyui_sageattention.sh"
read -rp "Press Enter to continue..."
