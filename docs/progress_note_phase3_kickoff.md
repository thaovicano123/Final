# Phase 3 Kickoff Note (Firmware IRQ Path)

## What was added
1. IRQ-specific firmware files:
   - `fw/irq_linker.ld`
   - `fw/irq_start.S`
   - `fw/main_irq.c`
2. IRQ firmware build script:
   - `scripts/build_fw_irq.sh`
3. SoC IRQ testbench and run script:
   - `tb/tb_soc_top_irq.v`
   - `scripts/run_phase3_irq_tb.sh`

## Key technical point
- PicoRV32 IRQ vector is configured at `0x00000010` in RTL (`PROGADDR_IRQ`).
- Firmware linker/startup now ensures `irq_vec` is placed and executable at `0x00000010`.

## Verification result
- Command: `./scripts/run_phase3_irq_tb.sh`
- PASS marker: `SOC_TOP_IRQ: PASS (irq_gpio_toggles=1880)`
- Artifacts:
  - `results/phase2/tb_soc_top_irq.log`
  - `results/phase2/tb_soc_top_irq.vcd`

## Why this matters
- Confirms end-to-end firmware-driven IRQ operation (not only peripheral-level TB stimulus).
- Establishes a strong base for Phase 3 firmware and low-power behavior validation.
