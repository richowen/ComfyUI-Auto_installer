---
license: mit
---
# UmeAiRT - ComfyUI auto installer

I'm sharing with you my installation script, which automatically provides ComfyUI, workflows, model Flux fp8 and GGUF, ...

Just run "ComfyUI-AllinOne-Auto_install.bat".
With a few questions at the beginning of the script, only the desired elements will be downloaded.

## What's included :

### ComfyUI :
- portable version nvidia cu121
- ComfyUI Manager
- new interface settings

### Workflow :
- TXT to IMG
- IMG to IMG
- Inpainting
- Outpainting
- Upscale
- ControlNet DEPTH
- ControlNet CANNY
- ControlNet HED
- PuLID
- IMG to TXT

### Flux1
- flux1-dev
- flux1-dev-fp8
- flux1-schnell-fp8
- clip_l
- t5xxl_fp8_e4m3fn
- t5xxl_fp16
- ae

### GGUF
- flux1-dev-Q8_0
- t5-v1_1-xxl-encoder-Q8_0
- flux1-dev-Q5_K_S
- t5-v1_1-xxl-encoder-Q5_K_M
- flux1-dev-Q4_K_S
- t5-v1_1-xxl-encoder-Q3_K_L

### Optimised text encoder
- ViT-L-14-TEXT-detail-improved-hiT-GmP-TE-only-HF

### Upscale Model :
- 4x_NMKD-Siax_200k
- 4x-ClearRealityV1

### ControlNet :
- flux-canny-controlnet-v3
- flux-depth-controlnet-v3
- flux-hed-controlnet-v3