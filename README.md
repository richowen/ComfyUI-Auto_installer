# ComfyUI Auto Installer

Easy setup for ComfyUI with WAN2.1 models and LoRA support.

## Quick Install

### Ubuntu/Linux
```bash
wget https://raw.githubusercontent.com/richowen/ComfyUI-Auto_installer/main/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh
```

## Features

- **WAN2.1 Models**: Text-to-video and image-to-video capabilities
- **Custom LoRAs**: Download from civitai.ai and huggingface.co
- **Model Options**: bf16, fp16, fp8, and GGUF quantized versions
- **GPU Optimization**: Standard and low VRAM modes

## Usage

After installation:
1. Run `./run_comfyui.sh` (or low VRAM version)
2. Open http://localhost:8188 in your browser

## Options

```bash
./bootstrap.sh --directory PATH --yes
```

- `--directory PATH`: Custom install location
- `--branch BRANCH`: Use specific branch
- `--yes`: Non-interactive mode
