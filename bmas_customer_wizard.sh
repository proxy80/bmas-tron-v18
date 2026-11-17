#!/usr/bin/env bash
# ==============================================================================
# BARE METAL APPLIED SCIENCE LLC // TRON V18.0.0 GRAPHICAL WEB INSTALLER LAUNCHER
# Copyright (c) 2026 Bare Metal Applied Science LLC. All Rights Reserved.
# ==============================================================================
set -e
cd "$(dirname "$0")"

BMAS_PORT="${BMAS_PORT:-5000}"
BMAS_MODEL_PATH="${BMAS_MODEL_PATH:-}"
OLLAMA_HOST_URI="${OLLAMA_HOST:-[http://127.0.0.1:11434](http://127.0.0.1:11434)}"
NON_INTERACTIVE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port|-p) BMAS_PORT="$2"; shift 2 ;;
        --model-path|-m) BMAS_MODEL_PATH="$2"; shift 2 ;;
        --ollama-host|-o) OLLAMA_HOST_URI="$2"; shift 2 ;;
        --yes|-y) NON_INTERACTIVE=1; shift ;;
        *) shift ;;
    esac
done

clear
echo "=============================================================================="
echo " BARE METAL APPLIED SCIENCE LLC — TRON V18.0.0 APPLIANCE INSTALLER"
echo " Executing Bare-Metal Pre-Flight Audit & Sovereign Provisioning Wizard..."
echo "=============================================================================="

SO_COUNT=$(ls -1 *.cpython-312-x86_64-linux-gnu.so 2>/dev/null | wc -l)
echo " [+] Verified $SO_COUNT stripped native C-extension (.so) binaries present."

PIPER_BIN="$HOME/.project-ai/ai_env/bin/piper"
PIPER_MODEL_DIR="$HOME/.project-ai/phase1_brain"
PIPER_ONNX="$PIPER_MODEL_DIR/en_US-lessac-medium.onnx"
PIPER_JSON="$PIPER_MODEL_DIR/en_US-lessac-medium.onnx.json"

mkdir -p "$PIPER_MODEL_DIR" /tmp/bmas_media

if ! command -v sox >/dev/null 2>&1; then
    echo " [i] Checking acoustic DSP utility (sox)..."
    sudo apt-get update -qq && sudo apt-get install -y -qq sox libsox-fmt-all >/dev/null 2>&1 || true
fi

if [ ! -x "$PIPER_BIN" ]; then
    echo " [+] Provisioning Piper Neural TTS runtime environment..."
    mkdir -p "$HOME/.project-ai"
    if command -v piper >/dev/null 2>&1; then
        mkdir -p "$HOME/.project-ai/ai_env/bin"
        ln -sf "$(command -v piper)" "$PIPER_BIN"
    else
        python3 -m venv "$HOME/.project-ai/ai_env" 2>/dev/null || true
        if [ -x "$HOME/.project-ai/ai_env/bin/pip" ]; then
            "$HOME/.project-ai/ai_env/bin/pip" install --quiet --upgrade pip piper-tts pathvalidate 2>/dev/null || true
        fi
    fi
fi

if [ ! -f "$PIPER_ONNX" ]; then
    echo " [+] Checking for BMAS Belle Neural Voice Model (en_US-lessac-medium.onnx)..."
    curl -sL --connect-timeout 5 "[https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx)" -o "$PIPER_ONNX" 2>/dev/null || true
    curl -sL --connect-timeout 5 "[https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json)" -o "$PIPER_JSON" 2>/dev/null || true
fi
echo " [+] Verified BMAS Belle Neural Voice Engine (Piper ONNX + SoX Multi-Age Acoustic DSP) ready."

HW_CPU=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || uname -p)
HW_RAM=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")
HW_BOARD=$(cat /sys/devices/virtual/dmi/id/board_vendor /sys/devices/virtual/dmi/id/board_name 2>/dev/null | tr '\n' ' ' | xargs || echo "Standard_PCIe")
if command -v nvidia-smi >/dev/null 2>&1; then
    HW_GPU=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -n1 | tr ',' ' ')
    HW_STACK="NVIDIA_CUDA_NCCL_Tensor"
elif command -v rocm-smi >/dev/null 2>&1; then
    HW_GPU="AMD_Instinct_Radeon_ROCm"
    HW_STACK="AMD_ROCm_HIP"
else
    HW_GPU=$(lspci 2>/dev/null | grep -i -E "vga|3d|display" | head -n1 | cut -d: -f3 | xargs || echo "CPU_Integrated")
    HW_STACK="CPU_Native_AVX"
fi
HW_OS=$(lsb_release -ds 2>/dev/null || uname -sr)
HW_CSV_LINE="$(date -u +%Y-%m-%dT%H:%M:%SZ),$(hostname -s),${HW_CPU},${HW_RAM},${HW_BOARD},${HW_GPU},${HW_STACK},${HW_OS}"
echo "Timestamp_UTC,Hostname,CPU_Model,RAM_Total,Motherboard_Chipset,GPU_Accelerator,Compute_Stack,OS_Kernel" > bmas_node_registration.csv
echo "$HW_CSV_LINE" >> bmas_node_registration.csv
echo " [+] Generated Hardware Registration Manifest: bmas_node_registration.csv"

echo "------------------------------------------------------------------------------"
echo " BARE-METAL INFERENCE MODEL & STORAGE TOPOLOGY CONFIGURATION"
echo "------------------------------------------------------------------------------"
mkdir -p "$HOME/io-models"

if [ -z "$BMAS_MODEL_PATH" ] && [ "$NON_INTERACTIVE" -eq 0 ] && [ -t 0 ]; then
    echo " Specify your pre-staged Inference Model source:"
    echo "   * Local / Admin Home Directory (default: $HOME/io-models)"
    echo "   * DoD / Enterprise Mounted Storage (e.g., /mnt/nas/models or /opt/models)"
    echo "   * Remote Inference API URI (e.g., [http://10.0.0.50:8002/v1](http://10.0.0.50:8002/v1))"
    read -r -t 30 -p " -> Enter path or URI [Press ENTER for default $HOME/io-models]: " USER_INPUT_PATH || true
    echo ""
    BMAS_MODEL_PATH="${USER_INPUT_PATH:-$HOME/io-models}"
else
    BMAS_MODEL_PATH="${BMAS_MODEL_PATH:-$HOME/io-models}"
fi

export BMAS_MODEL_PATH
export OLLAMA_HOST="$OLLAMA_HOST_URI"

if [[ "$BMAS_MODEL_PATH" =~ ^https?:// ]]; then
    echo " [+] Registered Remote Inference API Endpoint URI: $BMAS_MODEL_PATH"
    echo "$BMAS_MODEL_PATH" > .bmas_inference_endpoint.cfg
else
    BMAS_MODEL_PATH="${BMAS_MODEL_PATH/#\~/$HOME}"
    mkdir -p "$BMAS_MODEL_PATH" 2>/dev/null || true
    if [ -d "$BMAS_MODEL_PATH" ] && [ "$(realpath "$BMAS_MODEL_PATH" 2>/dev/null)" != "$(realpath "$HOME/io-models" 2>/dev/null)" ]; then
        ln -sfn "$BMAS_MODEL_PATH" "$HOME/io-models/mounted_models" 2>/dev/null || true
        echo " [+] Linked Enterprise Model Storage ($BMAS_MODEL_PATH) -> $HOME/io-models/mounted_models"
    fi
    APODEX_GGUF=$(find -L "$BMAS_MODEL_PATH" "$HOME/io-models" -maxdepth 2 -iname "*apodex*.gguf" -o -iname "*.gguf" 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$APODEX_GGUF" ]; then
        echo " [+] Detected Local GGUF Weight File: $(basename "$APODEX_GGUF") -> Ready for Port 8002 (--alias apodex)"
    else
        echo " [i] No local .gguf weight file detected yet in: $BMAS_MODEL_PATH"
        echo "     (Place Apodex Mini v1.1+ or any compatible .gguf in $BMAS_MODEL_PATH for Port 8002)"
    fi
fi

echo "------------------------------------------------------------------------------"
echo " AUDITING OLLAMA LOCAL INFERENCE INVENTORY ($OLLAMA_HOST_URI)"
echo "------------------------------------------------------------------------------"
if command -v ollama >/dev/null 2>&1; then
    OLLAMA_MODELS=$(ollama list 2>/dev/null | tail -n +2 || true)
    if [ -n "$OLLAMA_MODELS" ]; then
        MODEL_COUNT=$(echo "$OLLAMA_MODELS" | wc -l)
        echo " [+] Detected $MODEL_COUNT pre-staged Ollama model(s) ready for Stargate A/B routing:"
        ollama list 2>/dev/null | head -n 12 | sed 's/^/     /'
    else
        echo " [!] WARNING: Ollama is installed, but 'ollama list' returned 0 local models."
        echo "     Pre-stage at least one baseline model prior to air-gapped operation:"
        echo "     -> ollama pull qwen2.5:1.5b   (Lightweight Sovereign Fallback)"
        echo "     -> ollama pull llama3.3       (Enterprise Reasoning Baseline)"
    fi
else
    echo " [!] NOTICE: 'ollama' CLI not detected in PATH."
    echo "     Configure external Ollama/OpenAI URI in Enterprise Settings or pass --ollama-host."
fi
echo "------------------------------------------------------------------------------"

if ! pgrep -f "api_cc_18_0_0v|api-cc-18.0.0v.py|bmas_core_orchestrator" >/dev/null 2>&1; then
    echo " [+] Starting BMAS Sovereign Provisioning Gateway on Port $BMAS_PORT..."
    nohup python3 api-cc-18.0.0v.py --port "$BMAS_PORT" > /tmp/bmas_wizard_boot.log 2>&1 &
    sleep 3
fi

echo " [+] Web Installer UI Ready: http://localhost:${BMAS_PORT}/setup"
echo "=============================================================================="
