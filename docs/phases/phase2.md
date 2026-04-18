# Phase 2 (Week 3-6): SoC Architecture and RTL

## Target outcome
A complete RTL SoC with PicoRV32 + ROM + RAM + UART + Timer + GPIO + clock gating controls.

## Tasks
1. Draw block diagram and address map
2. Implement address decoder / simple interconnect
3. Implement CMU and clock gating enables for UART/Timer/GPIO
4. Implement SoC top wrapper and connect all modules

## Suggested outputs
- `docs/address_map.md`
- `rtl/soc_top.v`
- `rtl/bus_decoder.v`
- `rtl/cmu.v`
- `rtl/uart.v`, `rtl/timer.v`, `rtl/gpio.v`

## Exit criteria
- Lint/syntax clean for all major RTL modules
- Memory-mapped reads/writes route to correct peripheral
- Peripheral gated clocks follow enable registers correctly
