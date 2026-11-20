#!/usr/bin/env bash
# ==============================================================================
# BMAS TRON V18.0.0 — Sovereign Bare-Metal Pre-Flight & Provisioning Wizard
# Engineered by Bare Metal Applied Science LLC (Ventura, California, USA)
# Supports: Ubuntu 24.04 LTS | RHEL 9 / Rocky Linux 9 / Oracle Linux 9
# Hardening: PEP 668 venv, Air-Gapped Wheels, SELinux, fapolicyd, noexec Audit
# ==============================================================================
set -euo pipefail

BMAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BMAS_PORT="${BMAS_PORT:-5000}"
BMAS_MODEL_PATH="${BMAS_MODEL_PATH:-}"
BMAS_OLLAMA_HOST="${BMAS_OLLAMA_HOST:-http://127.0.0.1:11434}"
WHEELS_DIR="${BMAS_DIR}/wheels"
CHECK_ONLY=0

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
AMBER='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
log_info() { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_warn() { echo -e "${AMBER}[WARN]${NC}  $1"; }
log_err()  { echo -e "${RED}[FAIL]${NC}  $1"; }

# ------------------------------------------------------------------------------
# Parse CLI Flags (Preserves all documented V18 flags)
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port|-port)
      BMAS_PORT="$2"; shift 2 ;;
    --model-path|-model-path)
      BMAS_MODEL_PATH="$2"; shift 2 ;;
    --ollama-host|-ollama-host)
      BMAS_OLLAMA_HOST="$2"; shift 2 ;;
    --wheels-dir)
      WHEELS_DIR="$2"; shift 2 ;;
    --check-only)
      CHECK_ONLY=1; shift ;;
    --help|-h)
      cat << 'HELP'
Usage: ./bmas_customer_wizard.sh [OPTIONS]
  --port <PORT>            Bind port for TRON HUD (default: 5000 or $BMAS_PORT)
  --model-path <PATH|URI>  Local GGUF/model path or remote inference gateway URI
  --ollama-host <URL>      Ollama API base URL (default: http://127.0.0.1:11434)
  --wheels-dir <DIR>       Offline .whl directory for air-gapped pip install
  --check-only             Run bare-metal, Python, and STIG pre-flight checks only
HELP
      exit 0 ;;
    *)
      log_warn "Unrecognized argument ignored: $1"; shift ;;
  esac
done

echo -e "${CYAN}=============================================================================="
echo -e "  BMAS TRON V18.0.0 — BARE-METAL PRE-FLIGHT & SOVEREIGN PROVISIONING WIZARD"
echo -e "==============================================================================${NC}"

# ------------------------------------------------------------------------------
# 1. OS, Architecture, CPU AVX2, RAM, GPU & glibc Check
# ------------------------------------------------------------------------------
ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" ]]; then
  log_err "Unsupported architecture: ${ARCH}. Compiled .so binaries require x86_64."
  exit 1
fi

OS_ID="unknown"; OS_NAME="Unknown Linux"; OS_VER="unknown"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_NAME="${PRETTY_NAME:-Unknown Linux}"
  OS_VER="${VERSION_ID:-unknown}"
fi
log_info "Host OS: ${OS_NAME} (${ARCH})"

if grep -q -m1 "avx2" /proc/cpuinfo 2>/dev/null; then
  log_ok "CPU AVX2 instruction set detected."
else
  log_warn "AVX2 flag not detected in /proc/cpuinfo; local LLM performance may be degraded."
fi

TOTAL_RAM_GB="$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)"
if (( TOTAL_RAM_GB >= 16 )); then
  log_ok "System Memory: ${TOTAL_RAM_GB} GB RAM"
else
  log_warn "System Memory: ${TOTAL_RAM_GB} GB RAM (16 GB+ recommended for production)."
fi

if command -v nvidia-smi >/dev/null 2>&1; then
  GPU_INFO="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -n 1 || true)"
  [[ -n "$GPU_INFO" ]] && log_ok "NVIDIA GPU detected: ${GPU_INFO}" || log_info "nvidia-smi present, no active GPU reported."
else
  log_info "No NVIDIA GPU detected (CPU unified-memory / remote gateway mode)."
fi

GLIBC_VER="$(ldd --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+$' || echo "0.0")"
log_info "System glibc version: ${GLIBC_VER}"
if [[ "$OS_ID" =~ ^(rhel|rocky|almalinux|ol|centos)$ ]] && [[ "$GLIBC_VER" == "2.34" ]]; then
  log_warn "RHEL 9 family detected (glibc 2.34). Ensure you are running the BMAS RHEL 9 / glibc 2.34 RPM or .so bundle (Ubuntu 24.04 glibc 2.39 .so binaries will fail ABI load)."
fi

# ------------------------------------------------------------------------------
# 2. Filesystem Path & DISA STIG Security Profile Audit (noexec, SELinux, fapolicyd)
# ------------------------------------------------------------------------------
if [[ "$EUID" -eq 0 ]]; then
  log_warn "Running as root. For DISA STIG compliance, deploy under /opt/bmas-tron owned by a non-login service user (bmas-svc)."
fi

if [[ "$BMAS_DIR" == /home/* ]]; then
  MNT_OPTS="$(findmnt -no OPTIONS -T "$BMAS_DIR" 2>/dev/null || true)"
  if [[ "$MNT_OPTS" == *noexec* ]]; then
    log_err "Install path ${BMAS_DIR} is mounted with 'noexec'! Compiled .so binaries and venv cannot execute here."
    echo "         Move appliance to /opt/bmas-tron and re-run."
    exit 1
  else
    log_info "Running from ${BMAS_DIR} (Production DISA STIG standard path: /opt/bmas-tron)."
  fi
else
  log_ok "Enterprise install path: ${BMAS_DIR}"
fi

if command -v getenforce >/dev/null 2>&1; then
  SE_STATE="$(getenforce 2>/dev/null || echo "Disabled")"
  if [[ "$SE_STATE" == "Enforcing" ]]; then
    log_warn "SELinux is Enforcing. If port ${BMAS_PORT} or Nginx passive mirroring is blocked, run:"
    echo "         sudo semanage port -a -t http_port_t -p tcp ${BMAS_PORT}"
    echo "         sudo setsebool -P httpd_can_network_connect 1"
  else
    log_info "SELinux state: ${SE_STATE}"
  fi
fi

if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet fapolicyd 2>/dev/null; then
  log_warn "fapolicyd is ACTIVE. Non-RPM .so binaries and venv files must be trusted:"
  echo "         sudo fapolicyd-cli --file add ${BMAS_DIR}/ --trust-file bmas-tron"
  echo "         sudo fapolicyd-cli --update"
fi

# ------------------------------------------------------------------------------
# 3. Python 3.12 Detection & Dedicated Virtual Environment (PEP 668 Safe)
# ------------------------------------------------------------------------------
PY_BIN=""
if command -v python3.12 >/dev/null 2>&1; then
  PY_BIN="$(command -v python3.12)"
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; raise SystemExit(0 if sys.version_info[:2]==(3,12) else 1)' 2>/dev/null; then
  PY_BIN="$(command -v python3)"
fi

if [[ -z "$PY_BIN" ]]; then
  log_err "Python 3.12 (cpython-312) is required to load BMAS TRON V18 .so binaries."
  if [[ "$OS_ID" =~ ^(rhel|rocky|almalinux|ol|centos)$ ]]; then
    echo "         Install on RHEL 9 / Rocky 9:  sudo dnf install -y python3.12 python3.12-pip"
  else
    echo "         Install on Ubuntu 24.04 LTS:  sudo apt update && sudo apt install -y python3.12 python3.12-venv python3-pip"
  fi
  exit 1
fi
log_ok "Python interpreter: ${PY_BIN} ($("$PY_BIN" --version))"

VENV_DIR="${BMAS_DIR}/venv"
if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  log_info "Creating isolated Python 3.12 virtual environment at ${VENV_DIR}..."
  if ! "$PY_BIN" -m venv "$VENV_DIR"; then
    log_err "Failed to create venv. On Ubuntu install 'python3.12-venv'; on RHEL 9 install 'python3.12-pip'."
    exit 1
  fi
fi
VENV_PY="${VENV_DIR}/bin/python"
VENV_PIP="${VENV_DIR}/bin/pip"
log_ok "Virtual environment active: ${VENV_DIR}"

# Verify required Python packages
MISSING_PKGS=()
for pkg in flask requests pymysql cryptography; do
  if ! "$VENV_PY" -c "import ${pkg}" 2>/dev/null; then
    MISSING_PKGS+=("$pkg")
  fi
done

if (( ${#MISSING_PKGS[@]} > 0 )); then
  log_warn "Missing Python packages in venv: ${MISSING_PKGS[*]}"
  if [[ -d "$WHEELS_DIR" ]] && ls "${WHEELS_DIR}"/*.whl >/dev/null 2>&1; then
    log_info "Air-gapped wheelhouse detected at ${WHEELS_DIR}. Installing offline..."
    "$VENV_PIP" install --no-index --find-links="$WHEELS_DIR" -r "${BMAS_DIR}/requirements.txt"
  else
    log_info "Attempting online install into ${VENV_DIR}..."
    if ! "$VENV_PIP" install -r "${BMAS_DIR}/requirements.txt"; then
      log_err "Online pip install failed (air-gapped host?)."
      echo "         On a connected staging box, run:"
      echo "           pip3.12 download -r requirements.txt -d ./wheels"
      echo "         Transfer ./wheels to ${BMAS_DIR}/wheels and re-run this wizard."
      exit 1
    fi
  fi
  log_ok "All Python runtime dependencies verified inside venv."
else
  log_ok "All Python runtime dependencies (flask, requests, pymysql, cryptography) verified."
fi

# ------------------------------------------------------------------------------
# 4. Compiled Cython .so Binary & Ollama Pre-Flight Audit
# ------------------------------------------------------------------------------
SO_COUNT="$(find "$BMAS_DIR" -maxdepth 1 -name '*.cpython-312-x86_64-linux-gnu.so' | wc -l)"
if (( SO_COUNT == 0 )); then
  log_err "No compiled .cpython-312-x86_64-linux-gnu.so binaries found in ${BMAS_DIR}."
  exit 1
fi
log_ok "Verified ${SO_COUNT} compiled Cython .so subsystem binaries."

if command -v ollama >/dev/null 2>&1; then
  if ollama list >/dev/null 2>&1; then
    MODEL_COUNT="$(ollama list 2>/dev/null | tail -n +2 | wc -l)"
    log_ok "Ollama service reachable (${MODEL_COUNT} local models staged)."
    if ! ollama list 2>/dev/null | grep -q "qwen2.5:1.5b"; then
      log_warn "Baseline Ox Mini classifier 'qwen2.5:1.5b' not found. Stage with: ollama pull qwen2.5:1.5b"
    fi
  else
    log_warn "Ollama binary installed but daemon not responding at ${BMAS_OLLAMA_HOST}."
  fi
else
  log_info "Local Ollama CLI not found (using remote gateway: ${BMAS_OLLAMA_HOST})."
fi

if [[ -n "$BMAS_MODEL_PATH" ]]; then
  log_info "Configured model path / URI: ${BMAS_MODEL_PATH}"
fi

# ------------------------------------------------------------------------------
# 5. Exit if --check-only, Otherwise Launch TRON V18 Command Center
# ------------------------------------------------------------------------------
if (( CHECK_ONLY == 1 )); then
  echo -e "${GREEN}=============================================================================="
  echo -e "  PRE-FLIGHT AUDIT COMPLETE — HOST READY FOR BMAS TRON V18.0.0 ON PORT ${BMAS_PORT}"
  echo -e "==============================================================================${NC}"
  exit 0
fi

export BMAS_HOME="$BMAS_DIR"
export BMAS_PORT="$BMAS_PORT"
export BMAS_OLLAMA_HOST="$BMAS_OLLAMA_HOST"
[[ -n "$BMAS_MODEL_PATH" ]] && export BMAS_MODEL_PATH="$BMAS_MODEL_PATH"

log_info "Launching BMAS TRON V18.0.0 on port ${BMAS_PORT}..."
cd "$BMAS_DIR"
exec "$VENV_PY" "${BMAS_DIR}/api-cc-18.0.0v.py"
