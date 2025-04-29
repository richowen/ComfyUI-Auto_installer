#!/usr/bin/env bash

# Source the virtual environment if it exists
if [ -d "$(dirname "$0")/../comfyui_venv" ]; then
    source "$(dirname "$0")/../comfyui_venv/bin/activate"
    cd "$(dirname "$0")/../ComfyUI"
    python main.py --use-pytorch-cross-attention --use-xformers --use-sageattention
else
    cd "$(dirname "$0")/../ComfyUI"
    python3 main.py --use-pytorch-cross-attention --use-xformers --use-sageattention
fi

read -rp "Press Enter to continue..."
