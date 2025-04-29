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
logFile="$installPath/logs/lora_downloader.txt"

show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='◐◓◑◒'  # Cute donut spinner
    local i=0
    local elapsed=0

    tput civis  # Hide cursor
    echo -ne "\e[1;36m$message \e[0m"

    while kill -0 "$pid" 2>/dev/null; do
        local idx=$((i % ${#spinstr}))
        local ch="${spinstr:$idx:1}"
        printf "\r\e[1;36m$message \e[0m[%s] \e[2m(%ds)\e[0m" "$ch" "$elapsed"
        sleep "$delay"
        i=$((i + 1))
        elapsed=$((elapsed + 1))
    done

    printf "\r\e[1;32m$message done! (%ds)\e[0m\n" "$elapsed"
    tput cnorm  # Show cursor again
}

# Function to show progress for file downloads
download_with_progress() {
    local url=$1
    local output_file=$2
    local message=$3
    
    echo -e "${YELLOW}$message${NC}"
    curl -L --progress-bar -o "$output_file" "$url" >> "$logFile" 2>&1
    echo -e " -> Downloaded to $(basename "$output_file")"
}

# Check for ComfyUI folder
if [ -d "$installPath/ComfyUI" ]; then
    echo "ComfyUI folder detected"
    modelsPath="$installPath/ComfyUI/models"
else
    echo "ComfyUI folder not detected, please run the main installer first."
    read -rp "Press Enter to exit..."
    exit 1
fi

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

echo -e "${YELLOW}=== ComfyUI LoRA Downloader ===${NC}"
echo -e "${YELLOW}This script will help you download LoRA models from civitai.ai or Hugging Face${NC}"

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

echo -e "${YELLOW}LoRA download process completed.${NC}"
read -rp "Press Enter to continue..."
