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

# Create loras directory if it doesn't exist
mkdir -p "$modelsPath/loras"

# Function to download file with Civitai API key
download_with_civitai_api() {
    local url=$1
    local output_file=$2
    local message=$3
    local api_key=$4
    
    echo -e "${YELLOW}$message${NC}"
    curl -L --progress-bar -H "Authorization: Bearer $api_key" -o "$output_file" "$url" >> "$logFile" 2>&1
    echo -e " -> Downloaded to $(basename "$output_file")"
}

# Ask user if they want to download custom LoRAs
while true; do
    echo -e "${YELLOW}Do you want to download custom LoRAs from civitai.ai or Hugging Face?${NC}"
    echo -e "${GREEN}Y) Yes${NC}"
    echo -e "${GREEN}N) No${NC}"
    read -rp "Enter your choice (Y/N) and press Enter: " LORA_CHOICE
    
    case "$LORA_CHOICE" in
        [Yy]) DOWNLOAD_LORAS="yes"; break ;;
        [Nn]) DOWNLOAD_LORAS="no"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter Y or N.${NC}" ;;
    esac
done

# Download custom LoRAs if selected
if [ "${DOWNLOAD_LORAS:-no}" = "yes" ]; then
    # Initialize Civitai API key as empty
    CIVITAI_API_KEY=""
    
    # Ask for Civitai API key
    echo -e "${YELLOW}If you plan to download from Civitai.ai, please enter your API key.${NC}"
    echo -e "${YELLOW}(You can get this from https://civitai.com/user/account)${NC}"
    echo -e "${YELLOW}If you don't have one or won't use Civitai, just press Enter to skip.${NC}"
    read -rp "Civitai API Key: " CIVITAI_API_KEY
    
    # Create arrays to store URLs and filenames
    declare -a LORA_URLS
    declare -a LORA_FILENAMES
    declare -a LORA_TYPES  # To track if URL is from civitai or huggingface
    
    echo -e "${YELLOW}Enter the civitai.ai or Hugging Face URLs for LoRAs.${NC}"
    echo -e "${YELLOW}Enter one URL per line. Type 'done' when finished.${NC}"
    
    # Collect URLs
    while true; do
        read -rp "URL (or 'done'): " LORA_URL
        
        if [[ "$LORA_URL" == "done" ]]; then
            break
        fi
        
        # Validate URL format and identify type
        if [[ "$LORA_URL" == *"civitai.ai"* ]]; then
            # Check if API key is provided for Civitai URLs
            if [ -z "$CIVITAI_API_KEY" ]; then
                echo -e "${RED}Warning: No Civitai API key provided. Download may fail.${NC}"
                echo -e "${YELLOW}Do you want to provide an API key now? (Y/N)${NC}"
                read -rp "Enter your choice: " PROVIDE_KEY
                
                if [[ "$PROVIDE_KEY" == [Yy] ]]; then
                    read -rp "Civitai API Key: " CIVITAI_API_KEY
                fi
            fi
            LORA_TYPES+=("civitai")
            LORA_URLS+=("$LORA_URL")
            echo -e "${GREEN}Added Civitai URL to download list!${NC}"
        elif [[ "$LORA_URL" == *"huggingface.co"* ]]; then
            LORA_TYPES+=("huggingface")
            LORA_URLS+=("$LORA_URL")
            echo -e "${GREEN}Added Hugging Face URL to download list!${NC}"
        else
            echo -e "${RED}Unsupported URL format. Please enter a civitai.ai or huggingface.co URL.${NC}"
            continue
        fi
    done
    
    # If no URLs were added, exit this section
    if [ ${#LORA_URLS[@]} -eq 0 ]; then
        echo -e "${YELLOW}No LoRAs selected for download.${NC}"
    else
        echo -e "${YELLOW}=== LoRAs to be downloaded: ====${NC}"
        
        # Process URLs to extract filenames
        for i in "${!LORA_URLS[@]}"; do
            LORA_URL="${LORA_URLS[$i]}"
            LORA_TYPE="${LORA_TYPES[$i]}"
            
            # Extract filename from URL
            if [[ "$LORA_TYPE" == "civitai" ]]; then
                # For civitai URLs, we need to use the API key when extracting the filename
                if [ -n "$CIVITAI_API_KEY" ]; then
                    FILENAME=$(curl -sI -H "Authorization: Bearer $CIVITAI_API_KEY" "$LORA_URL" | grep -i "content-disposition" | sed -n 's/.*filename=\([^;]*\).*/\1/p' | tr -d '"')
                else
                    FILENAME=$(curl -sI "$LORA_URL" | grep -i "content-disposition" | sed -n 's/.*filename=\([^;]*\).*/\1/p' | tr -d '"')
                fi
                
                # If filename extraction failed, use a default name
                if [ -z "$FILENAME" ]; then
                    FILENAME="civitai_lora_$i.safetensors"
                fi
            elif [[ "$LORA_TYPE" == "huggingface" ]]; then
                # For HuggingFace URLs, extract filename from the URL
                FILENAME=$(basename "$LORA_URL" | sed 's/?.*//')
                # If filename extraction failed, use a default name
                if [ -z "$FILENAME" ]; then
                    FILENAME="huggingface_lora_$i.safetensors"
                fi
            fi
            
            LORA_FILENAMES+=("$FILENAME")
            echo -e "${GREEN}$((i+1)). ${FILENAME}${NC}"
        done
        
        # Confirm downloads
        echo -e "${YELLOW}Do you want to download these LoRAs?${NC}"
        echo -e "${GREEN}Y) Yes${NC}"
        echo -e "${GREEN}N) No${NC}"
        read -rp "Enter your choice (Y/N) and press Enter: " CONFIRM_DOWNLOAD
        
        case "$CONFIRM_DOWNLOAD" in
            [Yy])
                # Download all selected LoRAs
                for i in "${!LORA_URLS[@]}"; do
                    LORA_URL="${LORA_URLS[$i]}"
                    LORA_TYPE="${LORA_TYPES[$i]}"
                    FILENAME="${LORA_FILENAMES[$i]}"
                    
                    if [[ "$LORA_TYPE" == "civitai" ]] && [ -n "$CIVITAI_API_KEY" ]; then
                        # For Civitai URLs with API key
                        download_with_civitai_api "$LORA_URL" "$modelsPath/loras/$FILENAME" "Downloading LoRA (${i+1}/${#LORA_URLS[@]}): ${FILENAME}..." "$CIVITAI_API_KEY"
                    else
                        # For Hugging Face URLs or Civitai without API key
                        download_with_progress "$LORA_URL" "$modelsPath/loras/$FILENAME" "Downloading LoRA (${i+1}/${#LORA_URLS[@]}): ${FILENAME}..."
                    fi
                done
                echo -e "${GREEN}All selected LoRAs have been downloaded!${NC}"
                ;;
            *)
                echo -e "${YELLOW}LoRA downloads cancelled.${NC}"
                ;;
        esac
    fi
fi

echo -e "${YELLOW}All models downloaded.${NC}"
read -rp "Press Enter to continue..."
