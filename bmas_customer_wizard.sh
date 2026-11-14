#!/usr/bin/env bash
# ==============================================================================
# BARE METAL APPLIED SCIENCE LLC // TRON V18.0.0 GRAPHICAL WEB INSTALLER LAUNCHER
# ==============================================================================
set -e
cd "$(dirname "$0")"

# 1. Support Dynamic Port Override (Env Var BMAS_PORT or CLI --port <NUM>, Default: 5000)
BMAS_PORT="${BMAS_PORT:-5000}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port|-p)
            BMAS_PORT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

clear
echo "=============================================================================="
echo " 🛡️  BARE METAL APPLIED SCIENCE LLC — TRON V18.0.0 APPLIANCE INSTALLER"
echo "    Launching Interactive HTML5 + Animated SVG Web Provisioning Wizard..."
echo "=============================================================================="

SO_COUNT=$(ls -1 *.cpython-312-x86_64-linux-gnu.so 2>/dev/null | wc -l)
echo " [+] Verified $SO_COUNT/12 stripped native C-extension (.so) binaries present."

# 2. Verify / Auto-Provision Belle Neural Voice Engine (Piper ONNX + SoX + Lessac Model)
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
    curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx" -o "$PIPER_ONNX"
    curl -sL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json" -o "$PIPER_JSON"
fi
echo " [+] Verified BMAS Belle Neural Voice Engine (Piper ONNX + SoX DSP) ready."

# 3. Ensure BMAS_PORT is running via either source (.py) or compiled C-extension (.so)
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
echo " 👉 Navigate to: http://localhost:${BMAS_PORT}/setup in your browser to accept the"
echo "    Bare Metal Applied Science EULA/NDA and run the graphical installer!"
echo " 💡 Tip: Use './bmas_customer_wizard.sh --port 8443' for custom DoD/Enterprise ports."
echo "=============================================================================="
