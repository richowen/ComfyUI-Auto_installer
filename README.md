# ComfyUI Auto Installer

Easy setup for ComfyUI with WAN2.1 models and LoRA support.

## Quick Install

### Ubuntu/Linux
```bash
find $HOME -name "bootstrap.sh" -type f -delete 2>/dev/null || true && wget https://raw.githubusercontent.com/richowen/ComfyUI-Auto_installer/main/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh
```

## Features

- **WAN2.1 Models**: Text-to-video and image-to-video capabilities
- **Custom LoRAs**: Download from civitai.ai and huggingface.co
- **Model Options**: bf16, fp16, fp8, and GGUF quantized versions
- **GPU Optimization**: Standard and low VRAM modes
- **MultiGPU Support**: Load and run models across multiple GPUs
- **Custom Node Auto-setup**: Automatically runs install.py scripts in custom nodes

## Installation Process

During installation, the script will:

1. Set up a Python virtual environment
2. Install ComfyUI and core dependencies
3. Install specialized packages (onnxruntime, insightface, facexlib, filterpy)
4. Set up acceleration packages (sageattention, triton, xformers)
5. Install custom nodes with their requirements
6. Run any install.py scripts found in custom nodes to complete their setup
7. Configure environment for optimal performance

## Usage

After installation:
1. Run one of the provided scripts:
   - `./run_comfyui.sh` (standard mode)
   - `./run_comfyui_lowvram.sh` (low VRAM mode)
   - `./scripts/run_nvidia_gpu-sageattention.sh` (SageAttention mode for better performance)
2. Open http://localhost:8188 in your browser

## Options

```bash
./bootstrap.sh --directory PATH --yes
```

- `--directory PATH`: Custom install location
- `--branch BRANCH`: Use specific branch
- `--yes`: Non-interactive mode
