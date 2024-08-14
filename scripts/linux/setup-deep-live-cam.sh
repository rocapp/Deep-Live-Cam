#!/usr/bin/env bash

# Exit if any command fails
set -e

# Setup your platform
echo "Setting up your platform..."

# Python
if ! command -v python &>/dev/null; then
    echo "Python is not installed. Please install Python 3.10 or later."
    exit 1
fi

# Pip
if ! command -v pip &>/dev/null; then
    echo "Pip is not installed. Please install Pip."
    exit 1
fi

# Git
if ! command -v git &>/dev/null; then
    echo "Git is not installed. Installing Git..."
    sudo apt-get update && sudo apt-get install -y git
fi

# FFMPEG
if ! command -v ffmpeg &>/dev/null; then
    echo "FFMPEG is not installed. Installing FFMPEG..."
    sudo apt-get update && sudo apt-get install -y ffmpeg
fi

if [ "$(basename $PWD)" = "Deep-Live-Cam" ]; then
    echo "Already in Deep-Live-Cam directory."
else
    # Clone Repository
    if [ -d "Deep-Live-Cam" ]; then
        echo "Deep-Live-Cam directory already exists."
        read -p "Do you want to overwrite? (Y/N): " overwrite
        if [[ $overwrite == "Y" ]]; then
            rm -rf Deep-Live-Cam
            git clone https://github.com/hacksider/Deep-Live-Cam.git
        else
            echo "Skipping clone, using existing directory."
        fi
    else
        git clone https://github.com/hacksider/Deep-Live-Cam.git
    fi
    cd Deep-Live-Cam
fi

# Download Models
echo "Downloading models..."
mkdir -p models
if [ -f "models/GFPGANv1.4.pth" ]; then
    wget https://huggingface.co/hacksider/deep-live-cam/resolve/main/GFPGANv1.4.pth -O models/GFPGANv1.4.pth
fi

if [ -f "models/inswapper_128_fp16.onnx" ]; then
    wget https://huggingface.co/netrunner-exe/Insight-Swap-models/resolve/main/inswapper_128.fp16.onnx -O models/inswapper_128_fp16.onnx
fi

# Install dependencies
echo "Creating a virtual environment..."
python -m venv venv
source venv/bin/activate

echo "Installing required Python packages..."
pip install --upgrade pip setuptools
pip install -r requirements.txt

echo "Setup complete. You can now run the application."

# GPU Acceleration Options
echo ""
echo "Choose the GPU Acceleration Option if applicable:"
echo "1. CUDA (Nvidia)"
echo "2. CoreML (Apple Silicon)"
echo "3. CoreML (Apple Legacy)"
echo "4. DirectML (Windows)"
echo "5. OpenVINO (Intel)"
echo "6. None"
read -p "Enter your choice (1-6): " choice

case $choice in
1)
    echo "Installing CUDA dependencies..."
    pip uninstall -y onnxruntime onnxruntime-gpu
    pip install onnxruntime-gpu==1.16.3
    exec_provider="cuda"
    ;;
2)
    echo "Installing CoreML (Apple Silicon) dependencies..."
    pip uninstall -y onnxruntime onnxruntime-silicon
    pip install onnxruntime-silicon==1.13.1
    exec_provider="coreml"
    ;;
3)
    echo "Installing CoreML (Apple Legacy) dependencies..."
    pip uninstall -y onnxruntime onnxruntime-coreml
    pip install onnxruntime-coreml==1.13.1
    exec_provider="coreml"
    ;;
4)
    # DirectML is a Windows-specific option, so it will not work on
    Linux
    echo "DirectML is not available on Linux."
    ;;
5)
    echo "Installing OpenVINO dependencies..."
    pip uninstall -y onnxruntime onnxruntime-openvino
    pip install onnxruntime-openvino==1.15.0
    exec_provider="openvino"
    ;;
6)
    echo "Skipping GPU acceleration setup."
    ;;
*)
    echo "Invalid choice. Skipping GPU acceleration setup."
    ;;
esac

# Run the application
if [[ -n ${exec_provider} ]]; then
    echo "Running the application with ${exec_provider} execution         
  provider..."
    python run.py --execution-provider ${exec_provider}
else
    echo "Running the application..."
    python run.py
fi
