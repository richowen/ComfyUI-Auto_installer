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
echo -e "${YELLOW}Supported URL formats:${NC}"
echo -e "${GREEN}1. Civitai direct download URL:${NC}"
echo -e "   https://civitai.com/api/download/models/1498121?type=Model&format=SafeTensor"
echo -e "${GREEN}2. Civitai model page URL with modelVersionId:${NC}"
echo -e "   https://civitai.com/models/929497?modelVersionId=1498121"
echo -e "${GREEN}3. Civitai model page URL (you'll be asked for modelVersionId):${NC}"
echo -e "   https://civitai.com/models/929497/aesthetic-quality-modifiers-masterpiece"
echo -e "${GREEN}4. Hugging Face URL:${NC}"
echo -e "   https://huggingface.co/username/modelname/resolve/main/filename.safetensors"
echo ""

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
    if [[ "$LORA_URL" == *"civitai.com"* ]]; then
        # Handle direct API download URLs
        if [[ "$LORA_URL" == *"/api/download/models/"* ]]; then
            echo -e "${GREEN}Civitai direct download URL detected.${NC}"
            # Already in the correct format
        # Convert Civitai model page URL to download URL if needed
        elif [[ "$LORA_URL" == *"modelVersionId="* ]]; then
            # Extract the model version ID from the URL
            MODEL_VERSION_ID=$(echo "$LORA_URL" | grep -oP 'modelVersionId=\K[0-9]+')
            if [ -n "$MODEL_VERSION_ID" ]; then
                DOWNLOAD_URL="https://civitai.com/api/download/models/$MODEL_VERSION_ID?type=Model&format=SafeTensor"
                echo -e "${GREEN}Converted Civitai page URL to download URL.${NC}"
                LORA_URL="$DOWNLOAD_URL"
            fi
        # Handle URLs like https://civitai.com/models/929497/aesthetic-quality-modifiers-masterpiece
        elif [[ "$LORA_URL" == *"/models/"* ]]; then
            # Extract model ID from the URL path
            MODEL_ID=$(echo "$LORA_URL" | grep -oP '/models/\K[0-9]+')
            
            if [ -n "$MODEL_ID" ]; then
                echo -e "${YELLOW}Fetching model information from Civitai API...${NC}"
                
                # API call to get model information
                MODEL_INFO=$(curl -s "https://civitai.com/api/v1/models/$MODEL_ID")
                
                # Parse JSON to extract the first version's ID (version 0)
                MODEL_VERSION_ID=$(echo "$MODEL_INFO" | grep -o '"modelVersions":\[[^]]*\]' | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
                
                if [ -n "$MODEL_VERSION_ID" ]; then
                    DOWNLOAD_URL="https://civitai.com/api/download/models/$MODEL_VERSION_ID?type=Model&format=SafeTensor"
                    echo -e "${GREEN}Successfully created download URL using Civitai API (using first version).${NC}"
                    LORA_URL="$DOWNLOAD_URL"
                else
                    # API call failed or couldn't parse the response, fall back to manual entry
                    echo -e "${YELLOW}Could not automatically determine model version ID.${NC}"
                    echo -e "${YELLOW}Please enter the modelVersionId manually:${NC}"
                    echo -e "${YELLOW}You can find this by:${NC}"
                    echo -e "${YELLOW}1. Look for '?modelVersionId=' in the browser URL, or${NC}"
                    echo -e "${YELLOW}2. Click 'Download' on the model page and check the URL${NC}"
                    echo -e "${YELLOW}   (it will contain /api/download/models/NUMBER)${NC}"
                    read -rp "Model Version ID: " MODEL_VERSION_ID
                    
                    if [ -n "$MODEL_VERSION_ID" ]; then
                        DOWNLOAD_URL="https://civitai.com/api/download/models/$MODEL_VERSION_ID?type=Model&format=SafeTensor"
                        echo -e "${GREEN}Created download URL from manually entered version ID.${NC}"
                        LORA_URL="$DOWNLOAD_URL"
                    fi
                fi
            else
                # Could not extract model ID from URL
                echo -e "${RED}Could not extract model ID from URL.${NC}"
                echo -e "${YELLOW}Please enter the model version ID manually:${NC}"
                read -rp "Model Version ID: " MODEL_VERSION_ID
                
                if [ -n "$MODEL_VERSION_ID" ]; then
                    DOWNLOAD_URL="https://civitai.com/api/download/models/$MODEL_VERSION_ID?type=Model&format=SafeTensor"
                    echo -e "${GREEN}Created download URL from model version ID.${NC}"
                    LORA_URL="$DOWNLOAD_URL"
                fi
            fi
        fi
        
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
