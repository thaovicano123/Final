# SoC Low Power with PicoRV32 (ASIC) - Execution Workspace

This workspace is a practical execution plan for a 15-week graduation project.

## Goal
Build a small SoC using PicoRV32, integrate low power clock gating, verify by simulation,
and compare synthesis reports (power/area/timing) with and without clock gating.

## Project structure
- `docs/`: roadmap, phase documents, and weekly checklists
- `rtl/`: SoC RTL (top, bus decoder, peripherals, clock management)
- `tb/`: testbenches and simulation support files
- `fw/`: firmware source, linker script, startup code, hex/bin outputs
- `syn/`: synthesis scripts and constraints
- `scripts/`: helper scripts for setup/build/sim/synthesis flow
- `third_party/`: external IPs (PicoRV32 source)
- `results/`: generated reports, waveforms, and logs

## Week 1 immediate objective
Do only this first:
1. Install Ubuntu tools (iverilog, gtkwave, git, build tools)
2. Clone PicoRV32 source
3. Run author-provided testbench once and confirm output appears

See details in:
- `docs/phases/phase1.md`
- `docs/checklists/week1.md`
- `scripts/setup_ubuntu_tools.sh`
- `scripts/run_picorv32_smoketest.sh`
