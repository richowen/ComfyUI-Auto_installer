@echo off
setlocal enabledelayedexpansion

set "installPath=%CD%"
set "basePath=%installPath%\ComfyUI_windows_portable"
set "comfyPath=%basePath%\ComfyUI"
set "customNodesPath=%comfyPath%\custom_nodes"
set "modelsPath=%comfyPath%\models"

if not exist "%installPath%\logs" mkdir "%installPath%\logs"

curl -L -o banner.txt https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/banner.txt?download=true >> "%installPath%\logs\install.txt" 2>&1
echo -------------------------------------------------------------------------------[34m
type banner.txt
echo [0m-------------------------------------------------------------------------------
echo                     ComfyUI - WAN2.1 - All in one installer                          
echo                                                            V2.2 for CUDA 12.8         
echo -------------------------------------------------------------------------------
del /f banner.txt

REM Check if 7-Zip is installed and get its path
for %%I in (7z.exe) do set "SEVEN_ZIP_PATH=%%~$PATH:I"
if not defined SEVEN_ZIP_PATH (
    if exist "%ProgramFiles%\7-Zip\7z.exe" (
        set "SEVEN_ZIP_PATH=%ProgramFiles%\7-Zip\7z.exe"
    ) else if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" (
        set "SEVEN_ZIP_PATH=%ProgramFiles(x86)%\7-Zip\7z.exe"
    ) else (
        echo 7-Zip is not installed. Downloading and installing...
        curl -L -o 7z-installer.exe https://www.7-zip.org/a/7z2201-x64.exe
        7z-installer.exe /S
        set "SEVEN_ZIP_PATH=%ProgramFiles%\7-Zip\7z.exe"
        if not exist "%SEVEN_ZIP_PATH%" (
            echo Installation of 7-Zip failed. Please install it manually and try again.
			pause
            exit /b 1
        )
        del 7z-installer.exe
    )
)

REM Check and install Git
git --version > NUL 2>&1
if %errorlevel% NEQ 0 (
    echo Installing Git...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/Git-2.41.0.3-64-bit.exe' -OutFile 'Git-2.41.0.3-64-bit.exe'; if ($LASTEXITCODE -ne 0) { exit 1 }}"
    if %errorlevel% NEQ 0 (
        echo Failed to download Git installer.
		pause
        exit /b
    )
    start /wait Git-2.41.0.3-64-bit.exe /VERYSILENT
    del Git-2.41.0.3-64-bit.exe
) 
echo [33mEnabling long paths for git...[0m
powershell -Command "Start-Process git -WindowStyle Hidden -ArgumentList 'config','--system','core.longpaths','true' -Verb RunAs"

REM Download ComfyUI
echo [33mDownloading ComfyUI...[0m
curl -L -o ComfyUI_windows_portable_nvidia.7z https://github.com/comfyanonymous/ComfyUI/releases/download/v0.3.30/ComfyUI_windows_portable_nvidia.7z

REM Extract ComfyUI
echo [33mExtracting ComfyUI...[0m
"%SEVEN_ZIP_PATH%" x ComfyUI_windows_portable_nvidia.7z -o"%CD%" -y  >> "%installPath%\logs\install.txt" 2>&1

REM Check if extraction was successful
if not exist "ComfyUI_windows_portable" (
    echo Extraction failed. Please check the downloaded file and try again.
	pause
    exit /b 1
)

REM Delete archive
del /f ComfyUI_windows_portable_nvidia.7z -force


REM Navigate to custom_nodes folder
REM Update ComfyUI
"%basePath%\python_embeded\python.exe" -m pip install --upgrade pip  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" "%basePath%\update\update.py" "%basePath%\ComfyUI"  >> "%installPath%\logs\install.txt" 2>&1
if exist update_new.py (
  move /y update_new.py update.py
  echo Running updater again since it got updated.
  "%basePath%\python_embeded\python.exe" "%basePath%\update\update.py" "%basePath%\ComfyUI" --skip_self_update  >> "%installPath%\logs\install.txt" 2>&1
)
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%basePath%/ComfyUI/requirements.txt"  >> "%installPath%\logs\install.txt" 2>&1



REM Clone ComfyUI-Manager
echo [33mInstalling ComfyUI-Manager...[0m
git clone https://github.com/ltdrdata/ComfyUI-Manager.git "%customNodesPath%/ComfyUI-Manager" >> "%installPath%\logs\install.txt" 2>&1

echo [33mInstalling additional nodes...[0m

echo   - Impact-Pack
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack "%customNodesPath%/ComfyUI-Impact-Pack" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Impact-Pack/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1
git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack "%customNodesPath%/ComfyUI-Impact-Pack/impact_subpack" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Impact-Pack/impact_subpack/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install ultralytics --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - GGUF
git clone https://github.com/city96/ComfyUI-GGUF "%customNodesPath%/ComfyUI-GGUF" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-GGUF/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - mxToolkit
git clone https://github.com/Smirnov75/ComfyUI-mxToolkit "%customNodesPath%/ComfyUI-mxToolkit" >> "%installPath%\logs\install.txt" 2>&1

echo   - Custom-Scripts
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts "%customNodesPath%/ComfyUI-Custom-Scripts" >> "%installPath%\logs\install.txt" 2>&1

echo   - KJNodes
git clone https://github.com/kijai/ComfyUI-KJNodes "%customNodesPath%/ComfyUI-KJNodes" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-KJNodes/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - WanVideoWrapper
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper "%customNodesPath%/ComfyUI-WanVideoWrapper" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-WanVideoWrapper/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - VideoHelperSuite
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite "%customNodesPath%/ComfyUI-VideoHelperSuite" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-VideoHelperSuite/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - Frame-Interpolation
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation "%customNodesPath%/ComfyUI-Frame-Interpolation" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - rgthree
git clone https://github.com/rgthree/rgthree-comfy "%customNodesPath%/rgthree-comfy" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/rgthree-comfy/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - Easy-Use
git clone https://github.com/yolain/ComfyUI-Easy-Use "%customNodesPath%/ComfyUI-Easy-Use" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Easy-Use/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - PuLID_Flux_ll
git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll "%customNodesPath%/ComfyUI_PuLID_Flux_ll" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI_PuLID_Flux_ll/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1
curl -L -o "%basePath%\python_embeded\insightface-0.7.3-cp312-cp312-win_amd64.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/insightface-0.7.3-cp312-cp312-win_amd64.whl?download=true  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install --use-pep517 facexlib  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install git+https://github.com/rodjjo/filterpy.git  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install onnxruntime==1.19.2 onnxruntime-gpu==1.17.1 "%basePath%\python_embeded\insightface-0.7.3-cp312-cp312-win_amd64.whl"  >> "%installPath%\logs\install.txt" 2>&1

echo   - HunyuanVideoMultiLora
git clone https://github.com/facok/ComfyUI-HunyuanVideoMultiLora "%customNodesPath%/ComfyUI-HunyuanVideoMultiLora" >> "%installPath%\logs\install.txt" 2>&1

echo   - was-node-suite-comfyui
git clone https://github.com/WASasquatch/was-node-suite-comfyui "%customNodesPath%/was-node-suite-comfyui" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/was-node-suite-comfyui/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - Florence2
git clone https://github.com/kijai/ComfyUI-Florence2  "%customNodesPath%/ComfyUI-Florence2">> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install transformers==4.49.0 --upgrade >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Florence2/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - Upscaler-Tensorrt
git clone https://github.com/yuvraj108c/ComfyUI-Upscaler-Tensorrt "%customNodesPath%/ComfyUI-Upscaler-Tensorrt" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install wheel-stub >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Upscaler-Tensorrt/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - MultiGPU
git clone https://github.com/pollockjj/ComfyUI-MultiGPU "%customNodesPath%/ComfyUI-MultiGPU" >> "%installPath%\logs\install.txt" 2>&1

echo   - WanStartEndFramesNative
git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative "%customNodesPath%/ComfyUI-WanStartEndFramesNative" >> "%installPath%\logs\install.txt" 2>&1

echo   - ComfyUI-Image-Saver
git clone https://github.com/alexopus/ComfyUI-Image-Saver "%customNodesPath%/ComfyUI-Image-Saver" >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install -r "%customNodesPath%/ComfyUI-Image-Saver/requirements.txt" --no-warn-script-location >> "%installPath%\logs\install.txt" 2>&1

echo   - ComfyUI_UltimateSDUpscale
git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale "%customNodesPath%/ComfyUI_UltimateSDUpscale" >> "%installPath%\logs\install.txt" 2>&1

mkdir "%comfyPath%\user\default\workflows"
echo [33mDownloading comfy settings...[0m
curl -L -o "%comfyPath%\user\default\comfy.settings.json" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/comfy.settings.json?download=true >> "%installPath%\logs\install.txt" 2>&1
echo [33mDownloading comfy workflow...[0m
curl -L -o "%comfyPath%\user\default\workflows\UmeAiRT-WAN21_workflow.7z" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/workflows/UmeAiRT-WAN21_workflow.7z?download=true >> "%installPath%\logs\install.txt" 2>&1
"%SEVEN_ZIP_PATH%" x "%comfyPath%\user\default\workflows\UmeAiRT-WAN21_workflow.7z" -o"%comfyPath%\user\default\workflows\" -y   >> "%installPath%\logs\install.txt" 2>&1
del /f "%comfyPath%\user\default\workflows\UmeAiRT-WAN21_workflow.7z" -force   >> "%installPath%\logs\install.txt" 2>&1

curl -L -o "%installPath%/UmeAiRT-Missing_nodes.bat" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/UmeAiRT-Missing_nodes.bat?download=true"  >> "%installPath%\logs\install.txt" 2>&1
curl -L -o "%installPath%/UmeAiRT-WAN2.1-Model_downloader.bat" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/UmeAiRT-WAN2.1-Model_downloader.bat?download=true"  >> "%installPath%\logs\install.txt" 2>&1
curl -L -o "%installPath%/UmeAiRT-FLUX-Model_downloader.bat" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/UmeAiRT-FLUX-Model_downloader.bat?download=true"  >> "%installPath%\logs\install.txt" 2>&1

REM Final steps based on user choice
curl -L -o "%basePath%/run_nvidia_gpu-LOWVRAM.bat" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/scripts/run_nvidia_gpu-LOWVRAM.bat?download=true
curl -L -o "%basePath%/run_nvidia_gpu-sageattention.bat" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/scripts/run_nvidia_gpu-sageattention.bat?download=true

echo [33mInstalling additional modules for Python...[0m

echo   - Visual Studio Build Tools
powershell -Command "Start-Process winget -WindowStyle Hidden -ArgumentList 'install','--id','Microsoft.VisualStudio.2022.BuildTools','-e','--source','winget','--override','--quiet --wait --norestart --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.20348' -Verb RunAs"

echo   - Python include/libs
curl -L -o "%basePath%\python_embeded\python_3.12.9_include_libs.zip" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/python_3.12.9_include_libs.zip?download=true  >> "%installPath%\logs\install.txt" 2>&1
tar -xf "%basePath%\python_embeded\python_3.12.9_include_libs.zip" -C "%basePath%\python_embeded"  >> "%installPath%\logs\install.txt" 2>&1

echo   - NVIDIA Apex
curl -L -o "%basePath%\python_embeded\apex-0.1-py3-none-any.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/apex-0.1-py3-none-any.whl  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install "%basePath%\python_embeded\apex-0.1-py3-none-any.whl"  >> "%installPath%\logs\install.txt" 2>&1

echo   - Triton
curl -L -o "%basePath%\python_embeded\triton-3.3.0-py3-none-any.whl" https://github.com/woct0rdho/triton-windows/releases/download/empty/triton-3.3.0-py3-none-any.whl  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install "%basePath%\python_embeded\triton-3.3.0-py3-none-any.whl"  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -s -m pip install triton-windows  >> "%installPath%\logs\install.txt" 2>&1

echo   - xformers
curl -L -o "%basePath%\python_embeded\mpmath-1.3.0-py3-none-any.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/mpmath-1.3.0-py3-none-any.whl  >> "%installPath%\logs\install.txt" 2>&1
curl -L -o xformers-0.0.30.zip https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/xformers-0.0.30.zip  >> "%installPath%\logs\install.txt" 2>&1
"%SEVEN_ZIP_PATH%" x xformers-0.0.30.zip -o"%basePath%\python_embeded\Lib\site-packages" >> "%installPath%\logs\install.txt" 2>&1
del /f xformers-0.0.30.zip -force
rem curl -L -o "%basePath%\python_embeded\xformers-0.0.30+3abeaa9e.d20250426-cp312-cp312-win_amd64.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/xformers-0.0.30%2B3abeaa9e.d20250426-cp312-cp312-win_amd64.whl  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install "%basePath%\python_embeded\mpmath-1.3.0-py3-none-any.whl"  >> "%installPath%\logs\install.txt" 2>&1
rem "%basePath%\python_embeded\python.exe" -m pip install --no-deps "%basePath%\python_embeded\xformers-0.0.30+3abeaa9e.d20250426-cp312-cp312-win_amd64.whl"  >> "%installPath%\logs\install.txt" 2>&1

echo   - SageAttention
curl -L -o "%basePath%\python_embeded\sageattention-2.1.1-cp312-cp312-win_amd64.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/sageattention-2.1.1-cp312-cp312-win_amd64.whl  >> "%installPath%\logs\install.txt" 2>&1
"%basePath%\python_embeded\python.exe" -m pip install "%basePath%\python_embeded\sageattention-2.1.1-cp312-cp312-win_amd64.whl"  >> "%installPath%\logs\install.txt" 2>&1

:CHOOSE_DOWNLOAD_WAN
REM Ask user for installation type
echo [33mWould you like to download WAN models?[0m
set /p "MODELS=Enter your choice (Y or N) and press Enter: "

if /i "%MODELS%"=="Y" (
    call "%installPath%\UmeAiRT-WAN2.1-Model_downloader.bat"
) else if /i "%MODELS%"=="N" (
    REM Do nothing, just continue
) else (
    echo [31mInvalid choice. Please enter Y or N.[0m
    goto CHOOSE_DOWNLOAD_WAN
)

:CHOOSE_DOWNLOAD_FLUX
REM Ask user for installation type
echo [33mWould you like to download FLUX models?[0m
set /p "MODELS=Enter your choice (Y or N) and press Enter: "

if /i "%MODELS%"=="Y" (
    call "%installPath%\UmeAiRT-FLUX-Model_downloader.bat"
) else if /i "%MODELS%"=="N" (
    REM Do nothing, just continue
) else (
    echo [31mInvalid choice. Please enter Y or N.[0m
    goto CHOOSE_DOWNLOAD_FLUX
)

echo [33mComfyUI installed.[0m
pause