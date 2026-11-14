#!/usr/bin/env bash
# ==============================================================================
# BARE METAL APPLIED SCIENCE LLC // TRON V18.0.0 GRAPHICAL WEB INSTALLER LAUNCHER
# ==============================================================================
set -e
cd "$(dirname "$0")"

BMAS_PORT="${BMAS_PORT:-5000}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port|-p) BMAS_PORT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

clear
echo "=============================================================================="
echo " 🛡️  BARE METAL APPLIED SCIENCE LLC — TRON V18.0.0 APPLIANCE INSTALLER"
echo "    Launching Interactive HTML5 + Animated SVG Web Provisioning Wizard..."
echo "=============================================================================="

SO_COUNT=$(ls -1 *.cpython-312-x86_64-linux-gnu.so 2>/dev/null | wc -l)
echo " [+] Verified $SO_COUNT/12 stripped native C-extension (.so) binaries present."

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
        python3 -m venv "$HOME/.project-ai/ai_env"
        "$HOME/.project-ai/ai_env/bin/pip" install --quiet --upgrade pip piper-tts pathvalidate
    fi
fi

if [ ! -f "$PIPER_ONNX" ]; then
    echo " [+] Downloading BMAS Belle Neural Voice Model (en_US-lessac-medium.onnx)..."
    curl -sL "[https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx)" -o "$PIPER_ONNX"
    curl -sL "[https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json)" -o "$PIPER_JSON"
fi
echo " [+] Verified BMAS Belle Neural Voice Engine (Piper ONNX + SoX Multi-Age Acoustic DSP) ready."

# 2B. Generate Non-Invasive Hardware Manifest CSV for License Registration
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

# 2C. Version-Agnostic Apodex Mini GGUF (v1.1 / v1.1.1 / v1.2+) Auto-Discovery on Port 8002
mkdir -p "$HOME/io-models"
APODEX_GGUF=$(find "$HOME/io-models" -maxdepth 1 -iname "*apodex*.gguf" 2>/dev/null | sort -V | tail -n 1)
if [ -n "$APODEX_GGUF" ]; then
    echo " [+] Detected Apodex GGUF Model: $(basename "$APODEX_GGUF") -> Ready for Port 8002 (--alias apodex)"
else
    echo " [i] Apodex 21GB GGUF Slot (~/io-models/): Compatible with ANY Apodex-1.1 / 1.1.x+ .gguf release."
    echo "     (System will use Sovereign Fallback qwen2.5:1.5b on :11434 until an Apodex .gguf is placed in ~/io-models/)"
fi


if ! pgrep -f "api_cc_18_0_0v|api-cc-18.0.0v.py" >/dev/null 2>&1; then
    echo " [+] Starting BMAS Sovereign Provisioning Gateway on Port $BMAS_PORT..."
    if [ -f "api-cc-18.0.0v.py" ]; then
        nohup python3 api-cc-18.0.0v.py --port "$BMAS_PORT" > /tmp/bmas_wizard_boot.log 2>&1 &
    else
        nohup python3 -c "import sys; sys.argv=['api-cc-18.0.0v.py', '--port', '$BMAS_PORT']; import api_cc_18_0_0v; api_cc_18_0_0v.run_cli_entrypoint()" > /tmp/bmas_wizard_boot.log 2>&1 &
    fi
    sleep 3
fi

echo " [+] Opening Web Installer UI: http://localhost:${BMAS_PORT}/setup"
if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    xdg-open "http://localhost:${BMAS_PORT}/setup" >/dev/null 2>&1 &
fi
echo "=============================================================================="
echo " 👉 Navigate to: http://localhost:${BMAS_PORT}/setup in your browser"
echo " 💡 Tip: Use './bmas_customer_wizard.sh --port 8443' for custom DoD/Enterprise ports."
echo "=============================================================================="
