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
