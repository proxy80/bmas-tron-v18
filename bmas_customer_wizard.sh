#!/usr/bin/env bash
# ==============================================================================
# BARE METAL APPLIED SCIENCE LLC // TRON V18.0.0 GRAPHICAL WEB INSTALLER LAUNCHER
# ==============================================================================
cd "$(dirname "$0")"
clear
echo "=============================================================================="
echo " 🛡️  BARE METAL APPLIED SCIENCE LLC — TRON V18.0.0 APPLIANCE INSTALLER"
echo "    Launching Interactive HTML5 + Animated SVG Web Provisioning Wizard..."
echo "=============================================================================="

SO_COUNT=$(ls -1 *.cpython-312-x86_64-linux-gnu.so 2>/dev/null | wc -l)
echo " [+] Verified $SO_COUNT/12 stripped native C-extension (.so) binaries present."

# Ensure Port 5000 is running so the Web Installer UI can serve /setup
if ! pgrep -f "api-cc-18.0.0v.py" >/dev/null 2>&1; then
    echo " [+] Starting BMAS Sovereign Provisioning Gateway on Port 5000..."
    nohup python3 api-cc-18.0.0v.py --port 5000 > /tmp/bmas_wizard_boot.log 2>&1 &
    sleep 3
fi

echo " [+] Opening Web Installer UI: http://localhost:5000/setup"
if command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    xdg-open "http://localhost:5000/setup" >/dev/null 2>&1 &
fi
echo "=============================================================================="
echo " 👉 Navigate to: http://localhost:5000/setup in your browser to accept the"
echo "    Bare Metal Applied Science EULA/NDA and run the graphical installer!"
echo "=============================================================================="
