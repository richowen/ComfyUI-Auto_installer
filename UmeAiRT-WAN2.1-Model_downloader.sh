#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
NC='\033[0m'

installPath="$(pwd)"
comfyPath="$installPath/ComfyUI"
modelsPath="$comfyPath/models"
mkdir -p "$installPath/logs"
logFile="$installPath/logs/model_downloader.txt"

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

# Function to show progress for file downloads
download_with_progress() {
    local url=$1
    local output_file=$2
    local message=$3
    
    echo -e "${YELLOW}$message${NC}"
    
    # Download file with progress bar
    curl -L --progress-bar -o "$output_file" "$url" | tee -a "$logFile" > /dev/null
    
    echo -e " -> Downloaded to $(basename "$output_file")"
}

# Ensure we have venv support
echo -e "${YELLOW}Ensuring Python venv support is installed...${NC}"
sudo apt-get update && sudo apt-get install -y python3-venv python3-full >> "$logFile" 2>&1 &
show_spinner $! "Installing Python venv packages..."

# Use or create virtual environment
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
    
    "$PIP" install --upgrade pip >> "$logFile" 2>&1 &
    show_spinner $! "Upgrading pip..."
fi

# Check for ComfyUI folder
if [ -d "$installPath/ComfyUI" ]; then
    echo "ComfyUI folder detected"
    modelsPath="$installPath/ComfyUI/models"
else
    echo "ComfyUI folder not detected, please run the main installer first."
    read -rp "Press Enter to exit..."
    exit 1
fi

# Create necessary model directories
echo -e "${YELLOW}Creating model directories...${NC}"
mkdir -p "$modelsPath/diffusion_models" "$modelsPath/vae" "$modelsPath/clip" "$modelsPath/clip_vision" "$modelsPath/upscale_models"

# Ask user for installation type
while true; do
    echo -e "${YELLOW}Do you want to download WAN models?${NC}"
    echo -e "${GREEN}A) bf16${NC}"
    echo -e "${GREEN}B) fp16${NC}"
    echo -e "${GREEN}C) fp8${NC}"
    echo -e "${GREEN}D) All${NC}"
    echo -e "${GREEN}E) No${NC}"
    read -rp "Enter your choice (A,B,C,D or E) and press Enter: " CHOICE
    
    case "$CHOICE" in
        [Aa]|[Bb]|[Cc]|[Dd]) DOWNLOAD="yes"; break ;;
        [Ee]) DOWNLOAD="no"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter A,B,C,D or E.${NC}" ;;
    esac
done

# Ask user if they want to download WAN GGUF Model
while true; do
    echo -e "${YELLOW}Do you want to download WAN text to video GGUF models?${NC}"
    echo -e "${GREEN}A) Q8_0 + T5_Q8 (24GB Vram)${NC}"
    echo -e "${GREEN}B) Q5_K_S + T5_Q5_K_M (16GB Vram)${NC}"
    echo -e "${GREEN}C) Q4_K_S + T5_Q3_K_L (less than 12GB Vram)${NC}"
    echo -e "${GREEN}D) All${NC}"
    echo -e "${GREEN}E) No${NC}"
    read -rp "Enter your choice (A,B,C,D or E) and press Enter: " WAN_GGUF_CHOICE
    
    case "$WAN_GGUF_CHOICE" in
        [Aa]|[Bb]|[Cc]|[Dd]) DOWNLOAD_GGUF="yes"; break ;;
        [Ee]) DOWNLOAD_GGUF="no"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter A,B,C,D or E.${NC}" ;;
    esac
done

# Ask user if they want to download WAN 480p GGUF Model
while true; do
    echo -e "${YELLOW}Do you want to download WAN image to video 480p GGUF models?${NC}"
    echo -e "${GREEN}A) Q8_0 + T5_Q8 (24GB Vram)${NC}"
    echo -e "${GREEN}B) Q5_K_S + T5_Q5_K_M (16GB Vram)${NC}"
    echo -e "${GREEN}C) Q4_K_S + T5_Q3_K_L (less than 12GB Vram)${NC}"
    echo -e "${GREEN}D) All${NC}"
    echo -e "${GREEN}E) No${NC}"
    read -rp "Enter your choice (A,B,C,D or E) and press Enter: " WAN_GGUF_CHOICE_480
    
    case "$WAN_GGUF_CHOICE_480" in
        [Aa]|[Bb]|[Cc]|[Dd]) DOWNLOAD_GGUF_480="yes"; break ;;
        [Ee]) DOWNLOAD_GGUF_480="no"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter A,B,C,D or E.${NC}" ;;
    esac
done

# Ask user if they want to download WAN 720p GGUF Model
while true; do
    echo -e "${YELLOW}Do you want to download WAN image to video 720p GGUF models?${NC}"
    echo -e "${GREEN}A) Q8_0 + T5_Q8 (24GB Vram)${NC}"
    echo -e "${GREEN}B) Q5_K_S + T5_Q5_K_M (16GB Vram)${NC}"
    echo -e "${GREEN}C) Q4_K_S + T5_Q3_K_L (less than 12GB Vram)${NC}"
    echo -e "${GREEN}D) All${NC}"
    echo -e "${GREEN}E) No${NC}"
    read -rp "Enter your choice (A,B,C,D or E) and press Enter: " WAN_GGUF_CHOICE_720
    
    case "$WAN_GGUF_CHOICE_720" in
        [Aa]|[Bb]|[Cc]|[Dd]) DOWNLOAD_GGUF_720="yes"; break ;;
        [Ee]) DOWNLOAD_GGUF_720="no"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter A,B,C,D or E.${NC}" ;;
    esac
done

# Download models based on user choice
if [ "${DOWNLOAD:-no}" = "yes" ]; then
    echo -e "${YELLOW}Downloading diffusion models file...${NC}"
    case "$CHOICE" in
        [Aa])
            echo "T2V bf16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_bf16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_t2v_14B_bf16.safetensors" "Downloading T2V 14B bf16 model..."
            echo "I2V bf16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors" "Downloading I2V 720p 14B bf16 model..."
            ;;
        [Bb])
            echo "T2V fp16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_t2v_14B_fp16.safetensors" "Downloading T2V 14B fp16 model..."
            echo "I2V fp16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_i2v_720p_14B_fp16.safetensors" "Downloading I2V 720p 14B fp16 model..."
            ;;
        [Cc])
            echo "T2V fp8 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_e4m3fn.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_t2v_14B_fp8_e4m3fn.safetensors" "Downloading T2V 14B fp8 model..."
            echo "I2V fp8 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" "Downloading I2V 720p 14B fp8 model..."
            ;;
        [Dd])
            echo "T2V bf16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_bf16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_t2v_14B_bf16.safetensors" "Downloading T2V 14B bf16 model..."
            echo "I2V bf16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_i2v_720p_14B_bf16.safetensors" "Downloading I2V 720p 14B bf16 model..."
            
            echo "T2V fp16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_t2v_14B_fp16.safetensors" "Downloading T2V 14B fp16 model..."
            echo "I2V fp16 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp16.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_i2v_720p_14B_fp16.safetensors" "Downloading I2V 720p 14B fp16 model..."
            
            echo "T2V fp8 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_e4m3fn.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_t2v_14B_fp8_e4m3fn.safetensors" "Downloading T2V 14B fp8 model..."
            echo "I2V fp8 Model :"
            download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors?download=true" "$modelsPath/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" "Downloading I2V 720p 14B fp8 model..."
            ;;
    esac
fi

# Download VAE file
download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true" "$modelsPath/vae/wan_2.1_vae.safetensors" "Downloading VAE file..."

# Download CLIP files
download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true" "$modelsPath/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "Downloading CLIP file..."

# Download GGUF models based on user choice
if [ "${DOWNLOAD_GGUF:-no}" = "yes" ]; then
    echo -e "${YELLOW}Downloading GGUF T2V Quant Model...${NC}"
    case "$WAN_GGUF_CHOICE" in
        [Aa])
            download_with_progress "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q8_0.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-t2v-14b-Q8_0.gguf" "Downloading T2V Q8_0 model..."
            ;;
        [Bb])
            download_with_progress "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q5_K_M.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-t2v-14b-Q5_K_M.gguf" "Downloading T2V Q5_K_M model..."
            ;;
        [Cc])
            download_with_progress "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q3_K_S.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-t2v-14b-Q3_K_S.gguf" "Downloading T2V Q3_K_S model..."
            ;;
        [Dd])
            download_with_progress "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q8_0.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-t2v-14b-Q8_0.gguf" "Downloading T2V Q8_0 model..."
            download_with_progress "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q5_K_M.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-t2v-14b-Q5_K_M.gguf" "Downloading T2V Q5_K_M model..."
            download_with_progress "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q3_K_S.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-t2v-14b-Q3_K_S.gguf" "Downloading T2V Q3_K_S model..."
            ;;
    esac
fi

if [ "${DOWNLOAD_GGUF_480:-no}" = "yes" ]; then
    echo -e "${YELLOW}Downloading 480p GGUF I2V Quant Model...${NC}"
    case "$WAN_GGUF_CHOICE_480" in
        [Aa])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf" "Downloading I2V 480p Q8_0 model..."
            ;;
        [Bb])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q5_K_M.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-480p-Q5_K_M.gguf" "Downloading I2V 480p Q5_K_M model..."
            ;;
        [Cc])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q3_K_S.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-480p-Q3_K_S.gguf" "Downloading I2V 480p Q3_K_S model..."
            ;;
        [Dd])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf" "Downloading I2V 480p Q8_0 model..."
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q5_K_M.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-480p-Q5_K_M.gguf" "Downloading I2V 480p Q5_K_M model..."
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q3_K_S.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-480p-Q3_K_S.gguf" "Downloading I2V 480p Q3_K_S model..."
            ;;
    esac
fi

if [ "${DOWNLOAD_GGUF_720:-no}" = "yes" ]; then
    echo -e "${YELLOW}Downloading 720p GGUF I2V Quant Model...${NC}"
    case "$WAN_GGUF_CHOICE_720" in
        [Aa])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q8_0.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-720p-Q8_0.gguf" "Downloading I2V 720p Q8_0 model..."
            ;;
        [Bb])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q5_K_M.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-720p-Q5_K_M.gguf" "Downloading I2V 720p Q5_K_M model..."
            ;;
        [Cc])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q3_K_S.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-720p-Q3_K_S.gguf" "Downloading I2V 720p Q3_K_S model..."
            ;;
        [Dd])
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q8_0.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-720p-Q8_0.gguf" "Downloading I2V 720p Q8_0 model..."
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q5_K_M.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-720p-Q5_K_M.gguf" "Downloading I2V 720p Q5_K_M model..."
            download_with_progress "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q3_K_S.gguf?download=true" "$modelsPath/diffusion_models/wan2.1-i2v-14b-720p-Q3_K_S.gguf" "Downloading I2V 720p Q3_K_S model..."
            ;;
    esac
fi

# Download clip vision
download_with_progress "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true" "$modelsPath/clip_vision/clip_vision_h.safetensors" "Downloading clip vision file..."

# Download upscale models
download_with_progress "https://huggingface.co/spaces/Marne/Real-ESRGAN/resolve/main/RealESRGAN_x4plus.pth?download=true" "$modelsPath/upscale_models/RealESRGAN_x4plus.pth" "Downloading RealESRGAN x4plus model..."
download_with_progress "https://huggingface.co/spaces/Marne/Real-ESRGAN/resolve/main/RealESRGAN_x4plus_anime_6B.pth?download=true" "$modelsPath/upscale_models/RealESRGAN_x4plus_anime_6B.pth" "Downloading RealESRGAN anime model..."

echo -e "${YELLOW}WAN models downloaded.${NC}"
read -rp "Press Enter to continue..."
