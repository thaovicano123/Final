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

## Firmware precision hardening (updated)
1. Startup now performs deterministic C runtime initialization:
   - copy `.data` from ROM load image to RAM runtime
   - clear `.bss`
2. Linker scripts now export explicit runtime symbols:
   - `_sidata`, `_sdata`, `_edata`, `_sbss`, `_ebss`
3. IRQ startup layout fixed for strict vector placement:
   - `_start` at `0x00000000` (reset stub)
   - `irq_vec` at `0x00000010` (PicoRV32 IRQ vector)
   - `_boot` moved to `.text` to avoid overlap
4. C firmware (`main.c`, `main_irq.c`) refactored with explicit MMIO register offsets for maintainability and auditability.

## Key technical point
- PicoRV32 IRQ vector is configured at `0x00000010` in RTL (`PROGADDR_IRQ`).
- Firmware linker/startup now ensures `irq_vec` is placed and executable at `0x00000010`.

## Verification result
- Command: `./scripts/run_phase3_irq_tb.sh`
- PASS marker: `SOC_TOP_IRQ: PASS (irq_gpio_toggles=1879)`
- Artifacts:
  - `results/phase2/tb_soc_top_irq.log`
  - `results/phase2/tb_soc_top_irq.vcd`

Additional evidence:
- `fw/firmware_irq.map` confirms `_start=0x00000000`, `irq_vec=0x00000010`, `_boot=0x00000070`.
- `./scripts/run_soc_top_smoke.sh` PASS with UART banner `Phase3 firmware smoke`.

## Why this matters
- Confirms end-to-end firmware-driven IRQ operation (not only peripheral-level TB stimulus).
- Establishes a strong base for Phase 3 firmware and low-power behavior validation.
