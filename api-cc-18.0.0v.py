#!/usr/bin/env python3
"""
BMAS TRON V18.0.0 — Sovereign Production Cython (.so) Entrypoint Launcher
Bare Metal Applied Science LLC
"""
import os
import sys

DIST_DIR = os.path.dirname(os.path.abspath(__file__))
if DIST_DIR not in sys.path:
    sys.path.insert(0, DIST_DIR)
os.chdir(DIST_DIR)

import bmas_core_gateway

if __name__ == "__main__":
    bmas_core_gateway.main() if hasattr(bmas_core_gateway, "main") else None
