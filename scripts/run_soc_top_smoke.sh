#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results/phase2

echo "[INFO] Building firmware..."
./scripts/build_fw.sh

echo "[INFO] Compiling soc_top smoke testbench..."
iverilog -g2012 -o results/phase2/tb_soc_top_smoke.vvp \
  tb/tb_soc_top_smoke.v third_party/picorv32/picorv32.v rtl/*.v

echo "[INFO] Running soc_top smoke simulation..."
vvp results/phase2/tb_soc_top_smoke.vvp | tee results/phase2/tb_soc_top_smoke.log

echo "[OK] Done."
echo "  - Log: results/phase2/tb_soc_top_smoke.log"
echo "  - VCD: results/phase2/tb_soc_top_smoke.vcd"
