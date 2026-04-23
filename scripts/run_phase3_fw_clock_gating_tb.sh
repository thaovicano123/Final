#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results/phase3

echo "[INFO] Building clock-gating firmware..."
./scripts/build_fw_gating.sh

echo "[INFO] Compiling phase3 firmware clock-gating testbench..."
iverilog -g2012 -o results/phase3/tb_phase3_fw_clock_gating.vvp \
  tb/tb_phase3_fw_clock_gating.v third_party/picorv32/picorv32.v rtl/*.v

echo "[INFO] Running phase3 firmware clock-gating simulation..."
vvp results/phase3/tb_phase3_fw_clock_gating.vvp | tee results/phase3/tb_phase3_fw_clock_gating.log

echo "[OK] Done."
echo "  - Log: results/phase3/tb_phase3_fw_clock_gating.log"
echo "  - VCD: results/phase3/tb_phase3_fw_clock_gating.vcd"
