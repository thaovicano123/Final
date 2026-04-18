#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results/phase2

echo "[INFO] Building Phase 2 testbench..."
iverilog -g2012 -o results/phase2/tb_phase2_mmio_irq_gating.vvp \
  tb/tb_phase2_mmio_irq_gating.v third_party/picorv32/picorv32.v rtl/*.v

echo "[INFO] Running Phase 2 testbench..."
vvp results/phase2/tb_phase2_mmio_irq_gating.vvp | tee results/phase2/tb_phase2_mmio_irq_gating.log

echo "[OK] Done."
echo "  - Log: results/phase2/tb_phase2_mmio_irq_gating.log"
echo "  - VCD: results/phase2/tb_phase2_mmio_irq_gating.vcd"
