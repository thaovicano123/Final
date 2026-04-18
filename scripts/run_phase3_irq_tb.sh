#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results/phase2

echo "[INFO] Building IRQ firmware..."
./scripts/build_fw_irq.sh

echo "[INFO] Compiling soc_top IRQ testbench..."
iverilog -g2012 -o results/phase2/tb_soc_top_irq.vvp \
  tb/tb_soc_top_irq.v third_party/picorv32/picorv32.v rtl/*.v

echo "[INFO] Running soc_top IRQ simulation..."
vvp results/phase2/tb_soc_top_irq.vvp | tee results/phase2/tb_soc_top_irq.log

echo "[OK] Done."
echo "  - Log: results/phase2/tb_soc_top_irq.log"
echo "  - VCD: results/phase2/tb_soc_top_irq.vcd"
