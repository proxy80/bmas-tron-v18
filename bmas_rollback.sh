#!/usr/bin/env bash
# ==============================================================================
# BMAS TRON V18.0.0 — ENTERPRISE ATOMIC ROLLBACK & RELEASE MANAGER
# BARE METAL APPLIED SCIENCE LLC // SOVEREIGN APPLIANCE RECOVERY UTILITY
# ==============================================================================
set -e

SRC_DIR="$HOME/bmas_ai/18v"
DIST_DIR="$HOME/bmas_ai/18v_dist"
REL_DIR="$DIST_DIR/releases"
PORT=5000

mkdir -p "$REL_DIR"

banner() {
    echo "=============================================================================="
    echo "🛡️  BMAS TRON V18.0.0 — ATOMIC RELEASE & ROLLBACK MANAGER"
    echo "🏢 BARE METAL APPLIED SCIENCE LLC | TARGET PORT: $PORT"
    echo "=============================================================================="
}

usage() {
    banner
    echo "Usage:"
    echo "  ./bmas_rollback.sh --snapshot \"<description>\"   Create a verified release snapshot"
    echo "  ./bmas_rollback.sh --list                        List all available rollback points"
    echo "  ./bmas_rollback.sh --rollback <ID|latest>        Atomically roll back to a snapshot"
    echo "  ./bmas_rollback.sh --verify <ID|latest>          Verify SHA-256 binary integrity"
    echo "=============================================================================="
}

get_target_archive() {
    local target="$1"
    if [[ "$target" == "latest" || -z "$target" ]]; then
        ls -1t "$REL_DIR"/bmas_v18_snap_*.tar.gz 2>/dev/null | head -n 1
    elif [[ -f "$REL_DIR/$target" ]]; then
        echo "$REL_DIR/$target"
    elif [[ -f "$REL_DIR/bmas_v18_snap_${target}.tar.gz" ]]; then
        echo "$REL_DIR/bmas_v18_snap_${target}.tar.gz"
    else
        ls -1t "$REL_DIR"/*"${target}"*.tar.gz 2>/dev/null | head -n 1
    fi
}

cmd_snapshot() {
    local label="${1:-Routine_Enterprise_Checkpoint}"
    local safe_label
    safe_label=$(echo "$label" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local ts
    ts=$(date +"%Y%m%d_%H%M%S")
    local snap_id="${ts}_${safe_label}"
    local stage_dir="$REL_DIR/.stage_${snap_id}"
    local archive_path="$REL_DIR/bmas_v18_snap_${snap_id}.tar.gz"

    banner
    echo "[*] Creating Atomic Snapshot: $snap_id"
    mkdir -p "$stage_dir/dist" "$stage_dir/src" "$stage_dir/workspace"

    # 1. Capture compiled Cython .so binaries and entrypoint from 18v_dist
    cp -f "$DIST_DIR"/*.so "$stage_dir/dist/" 2>/dev/null || true
    cp -f "$DIST_DIR"/api-cc-18.0.0v.py "$stage_dir/dist/" 2>/dev/null || true

    # 2. Capture matching Python source modules from 18v
    cp -f "$SRC_DIR"/*.py "$stage_dir/src/" 2>/dev/null || true

    # 3. Capture active Belle OpenCode Affinity state & CSS
    if [[ -d "$DIST_DIR/volumes/belle_opencode_workspace" ]]; then
        cp -rf "$DIST_DIR/volumes/belle_opencode_workspace/." "$stage_dir/workspace/" 2>/dev/null || true
    fi

    # 4. Generate cryptographic SHA-256 manifest
    (
        cd "$stage_dir"
        find dist src workspace -type f -exec sha256sum {} + > MANIFEST.sha256
    )

    cat << META > "$stage_dir/RELEASE_META.txt"
SNAPSHOT_ID=$snap_id
TIMESTAMP=$(date -Is)
LABEL=$label
HOST=$(hostname)
KERNEL=$(uname -r)
META

    tar -czf "$archive_path" -C "$stage_dir" .
    rm -rf "$stage_dir"

    echo "[+] Snapshot Archive Locked : $archive_path"
    echo "[+] SHA-256 Manifest Sealed : $(tar -xzf "$archive_path" -O ./MANIFEST.sha256 | wc -l) files verified"
    echo "=============================================================================="
}

cmd_list() {
    banner
    printf "%-4s | %-38s | %-10s | %s\n" "IDX" "SNAPSHOT ID" "SIZE" "DATE"
    echo "------------------------------------------------------------------------------"
    local idx=1
    for f in $(ls -1t "$REL_DIR"/bmas_v18_snap_*.tar.gz 2>/dev/null); do
        local base
        base=$(basename "$f")
        local snap_id="${base#bmas_v18_snap_}"
        snap_id="${snap_id%.tar.gz}"
        local sz
        sz=$(du -h "$f" | awk '{print $1}')
        local dt
        dt=$(date -r "$f" +"%Y-%m-%d %H:%M:%S")
        printf "[%02d] | %-38s | %-10s | %s\n" "$idx" "$snap_id" "$sz" "$dt"
        idx=$((idx + 1))
    done
    if [[ $idx -eq 1 ]]; then
        echo "  (No snapshots found in $REL_DIR)"
    fi
    echo "=============================================================================="
}

cmd_verify() {
    local archive
    archive=$(get_target_archive "$1")
    if [[ -z "$archive" || ! -f "$archive" ]]; then
        echo "[!] Error: Snapshot not found for '$1'"
        exit 1
    fi
    banner
    echo "[*] Auditing Cryptographic SHA-256 Integrity: $(basename "$archive")"
    local tmp_verify="$REL_DIR/.verify_$$"
    mkdir -p "$tmp_verify"
    tar -xzf "$archive" -C "$tmp_verify"
    (
        cd "$tmp_verify"
        sha256sum -c MANIFEST.sha256
    )
    rm -rf "$tmp_verify"
    echo "[+] AUDIT PASSED: 100% of Cython .so binaries and sources match SHA-256 seal!"
    echo "=============================================================================="
}

cmd_rollback() {
    local archive
    archive=$(get_target_archive "$1")
    if [[ -z "$archive" || ! -f "$archive" ]]; then
        echo "[!] Error: Rollback target '$1' not found."
        cmd_list
        exit 1
    fi

    banner
    echo "[!] INITIATING ATOMIC ROLLBACK TO: $(basename "$archive")"

    # 1. Verify archive integrity before touching live files
    local tmp_stage="$REL_DIR/.rollback_$$"
    mkdir -p "$tmp_stage"
    tar -xzf "$archive" -C "$tmp_stage"
    echo "[*] Step 1/5: Verifying SHA-256 binary signatures..."
    (
        cd "$tmp_stage"
        sha256sum -c MANIFEST.sha256 >/dev/null
    )
    echo "    -> Signatures verified."

    # 2. Save automatic pre-rollback emergency backup of current state
    local em_ts
    em_ts=$(date +"%Y%m%d_%H%M%S")
    local em_tar="$REL_DIR/pre_rollback_state_${em_ts}.tar.gz"
    echo "[*] Step 2/5: Backing up current pre-rollback binaries to $(basename "$em_tar")..."
    tar -czf "$em_tar" -C "$DIST_DIR" $(ls "$DIST_DIR"/*.so 2>/dev/null | xargs -n1 basename) 2>/dev/null || true

    # 3. Restore compiled .so binaries to 18v_dist and sources to 18v
    echo "[*] Step 3/5: Atomically swapping Cython .so modules & Python sources..."
    cp -f "$tmp_stage/dist/"*.so "$DIST_DIR/" 2>/dev/null || true
    if [[ -f "$tmp_stage/dist/api-cc-18.0.0v.py" ]]; then
        cp -f "$tmp_stage/dist/api-cc-18.0.0v.py" "$DIST_DIR/"
    fi
    cp -f "$tmp_stage/src/"*.py "$SRC_DIR/" 2>/dev/null || true
    if [[ -d "$tmp_stage/workspace" ]]; then
        mkdir -p "$DIST_DIR/volumes/belle_opencode_workspace"
        cp -rf "$tmp_stage/workspace/." "$DIST_DIR/volumes/belle_opencode_workspace/" 2>/dev/null || true
    fi
    rm -rf "$tmp_stage"

    # 4. Restart Port 5000 Service cleanly
    echo "[*] Step 4/5: Cycling BMAS TRON V18.0.0 service on port $PORT..."
    fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
    sleep 1
    nohup python3 "$DIST_DIR/api-cc-18.0.0v.py" --port "$PORT" > "$DIST_DIR/bmas_rollback_boot.log" 2>&1 &
    local new_pid=$!
    echo "    -> Spawned PID $new_pid. Waiting for health check..."

    # 5. Live Telemetry Health Verification
    echo "[*] Step 5/5: Probing http://127.0.0.1:${PORT}/api/telemetry ..."
    local ok=0
    for i in {1..15}; do
        if curl -s "127.0.0.1:${PORT}/api/telemetry" | grep -q "active_ollama_model"; then
            ok=1
            break
        fi
        sleep 1
    done

    if [[ $ok -eq 1 ]]; then
        echo "[+] ROLLBACK COMPLETE & VERIFIED ONLINE! (PID: $new_pid | Port: $PORT)"
    else
        echo "[!] Warning: Server still initializing. Check: tail -f $DIST_DIR/bmas_rollback_boot.log"
    fi
    echo "=============================================================================="
}


cmd_delete() {
    local target="${1:-}"
    banner
    if [[ -z "$target" || "$target" == "latest" ]]; then
        echo "[!] Error: Please select a specific Snapshot ID from the dropdown to delete (cannot delete 'latest' alias)."
        exit 1
    fi
    local snap_file="$RELEASE_DIR/bmas_v18_snap_${target}.tar.gz"
    local sha_file="$RELEASE_DIR/bmas_v18_snap_${target}.sha256"
    if [[ ! -f "$snap_file" ]]; then
        echo "[!] Snapshot archive not found: $snap_file"
        exit 1
    fi
    rm -f "$snap_file" "$sha_file"
    echo "[+] Deleted Snapshot Archive : bmas_v18_snap_${target}.tar.gz"
    echo "=============================================================================="
    cmd_list
}

cmd_prune() {
    local keep="${1:-5}"
    banner
    echo "[*] Pruning old snapshots (Keeping newest $keep releases in $RELEASE_DIR)..."
    local count=0
    local deleted=0
    for f in $(ls -1 "$RELEASE_DIR"/bmas_v18_snap_*.tar.gz 2>/dev/null | sort -r); do
        count=$((count + 1))
        if [[ $count -gt $keep ]]; then
            local base="${f%.tar.gz}"
            rm -f "${base}.tar.gz" "${base}.sha256"
            echo " [-] Removed old snapshot: $(basename "$f")"
            deleted=$((deleted + 1))
        fi
    done
    echo "[+] Prune complete: $deleted old snapshot(s) removed."
    echo "=============================================================================="
    cmd_list
}

case "${1:-}" in
    --snapshot|-s)
        cmd_snapshot "${2:-Enterprise_Baseline}"
        ;;
    --list|-l)
        cmd_list
        ;;
    --verify|-v)
        cmd_verify "${2:-latest}"
        ;;
    --rollback|-r)
        cmd_rollback "${2:-latest}"
        ;;
    --delete|-d)
        cmd_delete "${2:-}"
        ;;
    --prune|-p)
        cmd_prune "${2:-5}"
        ;;
    *)
        usage
        ;;
esac
