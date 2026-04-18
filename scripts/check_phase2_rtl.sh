#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

echo "[INFO] Compiling Phase-2 RTL with PicoRV32..."
iverilog -g2012 -o /tmp/soc_phase2_check.vvp third_party/picorv32/picorv32.v rtl/*.v

echo "[OK] RTL syntax/integration check passed."
