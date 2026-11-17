# 🛡️ BMAS TRON V18.0.0 — Sovereign AI & HPC Command Center Appliance
**Enterprise Bare-Metal AI Gateway, Multi-Node Galera Telemetry, & Cryptographic Release Manager**
**Engineered by Bare Metal Applied Science LLC** • *Ventura, California, USA*

---

## ⚠️ COMMERCIAL LICENSE REQUIRED FOR ACTIVATION
**BMAS TRON V18.0.0** is distributed as compiled, high-performance native Linux C-extension shared binaries (`.cpython-312-x86_64-linux-gnu.so`).

> **IMPORTANT:** This appliance requires a cryptographic hardware-bound **BMAS V18 License Key** to unlock full operational capabilities.
> Upon initial launch, the built-in **Sovereign Provisioning & License Wizard (`/setup`)** will compute your server's unique **Host Node Fingerprint ID**.
>
> 📧 **To Request an Evaluation or Commercial Production License Key:**
> Email **[jefferson@baremetalappliedscience.com](mailto:jefferson@baremetalappliedscience.com)** with:
> 1. Your Organization / Callsign
> 2. Your 16-Character **Host Node Fingerprint ID** (displayed on the `/setup` wizard screen)
> 3. Requested Tier (**30-Day Evaluation** or **Enterprise Sovereign Node License**)

---

## 🚀 Architectural Highlights
* **Native Cython Binary Execution (`.so`):** All 12 core subsystems are compiled into stripped `x86_64` shared objects for native C speed and IP protection.
* **🛡️ Atomic SHA-256 Release & Rollback Manager:** Non-blocking background snapshot engine with an 88vw wide-screen operator console, interactive rollback dropdown selector, SHA-256 verification, and one-click vault pruning.
* **🗄️ High-Availability MariaDB Galera Cluster + SQLite Fallback:** Seamless 3-node synchronous replication telemetry with automatic local SQLite fallback.
* **🧠 Multi-Engine Local AI Inference Routing:** Native orchestration for **Ollama (`:11434`)**, **GGUF `llama-server` (`:8002`)**, and **FastAPI/vLLM Bridges (`:8081`)**.
* **🔐 DoD PKI / mTLS & Active Directory RBAC Ready:** Integrated X.509 certificate lifecycle vault and role-based access control profiles.

---

## 🖥️ System Requirements
- **OS / Kernel:** Ubuntu 24.04 LTS (`x86_64`)
- **Python Runtime:** Python `3.12.x` (`cpython-312`)
- **CPU / GPU:** x86_64 CPU with AVX2 support; NVIDIA CUDA-capable GPU recommended

---

## 📦 Quick-Start Installation & Provisioning

### 1. Clone the Appliance Repository
```bash
git clone https://github.com/proxy80/bmas-tron-v18.git
cd bmas-tron-v18
```

### 2. Install Python 3.12 Runtime Dependencies
```bash
pip install flask requests pymysql cryptography
```

### 3. Launch the Graphical Provisioning & License Wizard
```bash
chmod +x bmas_customer_wizard.sh bmas_reset.sh bmas_rollback.sh
./bmas_customer_wizard.sh
```

### 4. Activate Your License
1. Open your browser to **`http://localhost:5000/setup`** (or `http://<YOUR_SERVER_IP>:5000/setup`).
2. Accept the **Bare Metal Applied Science LLC EULA & NDA**.
3. Copy the **Host Node Fingerprint ID** displayed on Step 2 and email it to **`jefferson@baremetalappliedscience.com`**.
4. Paste your issued `BMAS18-...` license key into the wizard to unlock the full WebGL Command Center HUD!

---
© 2026 Bare Metal Applied Science LLC. All Rights Reserved.

---

## 🗄️ Database Topology & Galera Integration Note
* **Default Standalone Mode:** Out-of-the-box deployments utilize our resilient local SQLite Sentry engine (`bmas_sentry_v15.db`), requiring zero external database setup for single-node installations.
* **Enterprise Multi-Node Galera Mode:** For high-availability multi-node telemetry synchronization, TRON includes the `bmas_galera_sync` native bridge (`:3306`). Enterprise operators are responsible for provisioning their underlying 3-node MariaDB Galera cluster infrastructure; TRON automatically discovers, connects, and synchronizes telemetry across the cluster or falls back gracefully to SQLite if the cluster is unreachable.


---

## 📖 Enhanced Enterprise User Guidebook & Operator Prerequisites

### 1. What BMAS TRON V18.0.0 Is & Operational Scope
**BMAS TRON V18.0.0** is an industrial, bare-metal Sovereign AI Gateway and High-Performance Computing (HPC) Command Center engineered for air-gapped defense networks, clinical research institutions, and enterprise data centers:
- **Multi-Engine Local Inference:** Unifies Ollama (`:11434`), GGUF `llama-server` (`:8002`), Apodex Mini 1.1v baselines, and FastAPI/vLLM bridges (`:8081`) with Stargate dual-chevron routing and 8 industry RAG affinities.
- **Empirical Hardware & CFO Telemetry:** Live GPU VRAM/clock/wattage telemetry, Shannon token entropy matrices, 3D Stargate routing visualizations, and Executive CFO OpEx audit reports.
- **Multi-Profile Neural Voice Synthesis (Belle Autopilot & TTS):** Integrated `BMASBelleAutopilot` engine backed by local Piper ONNX neural speech synthesis (`en_US-lessac-medium.onnx`), SoX acoustic pitch/tempo DSP contouring, and multi-age voice profiles.
- **Zero-Downtime State & High Availability:** SHA-256 atomic snapshot/rollback vault alongside dual-mode telemetry storage (zero-config local SQLite Sentry out of the box, or 3-node MariaDB Galera clustering on `:3306`).

### 2. Required Operator Skillset (Important Notice)
> **⚠️ ENTERPRISE SYSTEMS ENGINEERING PREREQUISITE:**
> This appliance is **not** a consumer desktop chat wrapper or a beginner plug-and-play script. Deploying and operating BMAS TRON V18.0.0 requires a Systems Engineer, Principal Infrastructure Architect, or Linux Administrator with proficiency in Ubuntu 24.04 LTS administration, Python 3.12 / compiled Cython shared binaries (`.so`), REST API & X.509 mTLS PKI certificates, and SQLite / MariaDB Galera database topologies.

### 3. Custom Port Override (DoD / KOTS / Enterprise Firewalls)
By default, the TRON Command Center binds to port **`5000`**. For DoD, KOTS, or enterprise environments where port `5000` is reserved, operators can dynamically bind the appliance to **`8443`** (or any accredited port) at launch:
```bash
./bmas_customer_wizard.sh --port 8443
# Or via environment variable:
BMAS_PORT=8443 ./bmas_customer_wizard.sh
```

---

## 🛡️ Enterprise Identity, Zero-Trust RBAC & DoD Authentication (`bmas_enterprise_auth.so`)

BMAS TRON V18.0.0 includes a compiled, zero-dependency Cython authentication engine designed for air-gapped DoD, banking, and sovereign enterprise environments:

* **🏢 Enterprise Active Directory & OpenLDAP (`AD_LDAP`)**: Native LDAP/LDAPS bind verification (`ldap://` / `ldaps://`) with domain group mapping (`Principal Architect`, `System Administrator`, `Security Auditor`).
* **🐧 Linux SSSD & PAM Integration (`SSSD_PAM`)**: Direct `pam_sss.so` host pipe authentication for RHEL, Rocky Linux, and Ubuntu appliances joined via `realm join` / `sssd`.
* **🔐 DoD RADIUS & RSA SecurID (`RADIUS_RSA` — RFC 2865)**: Pure-Python UDP 1812 client with MD5 attribute encryption supporting standard RADIUS `Access-Request` (Code 1), `Access-Accept` (Code 2), and multi-factor RSA SecurID `Access-Challenge` (Code 11) pin/token workflows.
* **⏳ DISA STIG Session Hardening**: Enforced 15-minute cryptographic idle-lock overlay (**Apodex Mini Virtual Eye**) with automatic Sovereign Local Vault (FNV-1a / Ed25519) offline failover.

---

## Bare-Metal & DoD Air-Gapped Pre-Flight Model Staging Guide

Before deploying **BMAS TRON V18.0.0** onto a bare-metal server or air-gapped enclave, operators must ensure that the target administrator account has read/execute access to a working **Ollama** runtime and/or pre-staged **GGUF** model weights.

### 1. Pre-Installation Model Preparation (Connected Staging -> Air-Gapped Target)
In DoD and enterprise environments where target nodes are air-gapped, model weights must be downloaded on an authorized staging workstation and transferred to the target server via accredited internal storage (`/mnt/...`, NFS/SAN share, or the designated administrator home directory):

* **Verify Ollama Service:** Ensure Ollama is installed and running under the administrator's service account (`ollama list`).
* **Pull Recommended Baseline Models Prior to Air-Gapping:**
  * **Sovereign Lightweight Fallback (Required Baseline):** `ollama pull qwen2.5:1.5b` or `ollama pull gemma:2b`
  * **Enterprise Reasoning & Multimodal:** `ollama pull llama3.3:latest`, `ollama pull qwen3.8:latest`, `ollama pull gemma4:12b`, or `ollama pull llava:latest`
  * **Code & Security Audit:** `ollama pull qwen2.5-coder:latest` or `ollama pull deepseek-r1:latest`
* **Apodex Mini GGUF Slot (`:8002`):** Stage your `apodex*.gguf` (v1.1 / v1.1.x+) weight file inside `~/io-models/` or any mounted enterprise directory (e.g., `/mnt/models/`).

### 2. Multi-Topology Installer Flags (`bmas_customer_wizard.sh`)
During installation, `./bmas_customer_wizard.sh` automatically audits `ollama list` and prompts the operator for their model storage location. Operators can also bind paths non-interactively via CLI flags:
* **Default Home Directory:** `./bmas_customer_wizard.sh`
* **Mounted DoD / NAS Storage:** `./bmas_customer_wizard.sh --port 8443 --model-path /mnt/enterprise_ai_models`
* **Remote Enterprise URI Gateway:** `./bmas_customer_wizard.sh --port 8443 --model-path https://<YOUR_GATEWAY_HOST_OR_IP>/v1 --ollama-host http://<YOUR_OLLAMA_SERVER_IP>:11434`

### 3. Third-Party Model Availability & Forward-Compatibility Disclaimer
* **Upstream Model Availability:** Third-party open-weight models listed above are maintained by their respective upstream publishers. **Bare Metal Applied Science LLC** does not control upstream repository retention. If a specific model tag is deprecated or superseded upstream, operators should substitute the latest stable release family available at deployment time.
* **Zero-Breakage API Guarantee:** The BMAS TRON V18.0.0 Stargate engine communicates strictly via standardized REST/JSON inference schemas (`:11434/api/tags`, `:8002/v1/chat/completions`, and `:8081`). Substituting newer model versions or updated parameter tags will **not** break the appliance control plane, telemetry, or RBAC security modules.
