# SoC Address Map (Phase 2)

| Region | Base Address | Size | Description |
|---|---:|---:|---|
| ROM | `0x0000_0000` | 64 KB | Instruction/data read memory (firmware image) |
| RAM | `0x1000_0000` | 64 KB | Data memory |
| UART | `0x2000_0000` | 4 KB | UART MMIO registers |
| Timer | `0x2000_1000` | 4 KB | Timer MMIO registers |
| GPIO | `0x2000_2000` | 4 KB | GPIO MMIO registers |
| CMU | `0x2000_3000` | 4 KB | Clock management + clock gating control |

## Peripheral register map (initial)

### UART (`0x2000_0000`)
- `0x00` TXDATA (W): write byte to transmit/debug print
- `0x04` STATUS (R): bit0 = tx_ready (always 1 in current model)

### Timer (`0x2000_1000`)
- `0x00` LOAD (RW): reload value
- `0x04` VALUE (R): current counter value
- `0x08` CTRL (RW): bit0=enable, bit1=irq_en, bit2=periodic
- `0x0C` IRQ_STATUS (RW1C): bit0 pending

### GPIO (`0x2000_2000`)
- `0x00` DATA_OUT (RW)
- `0x04` DATA_IN (R)
- `0x08` DIR (RW): 1=output, 0=input
- `0x0C` TOGGLE (W): toggle selected output bits

### CMU (`0x2000_3000`)
- `0x00` CLK_EN (RW): bit0=UART, bit1=TIMER, bit2=GPIO
- `0x04` CLK_STAT (R): latched enables (same as CLK_EN in this model)
