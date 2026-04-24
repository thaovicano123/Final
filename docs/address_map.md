# SoC Address Map (Phase 2)

| Region | Base Address | Size | Description |
|---|---:|---:|---|
| ROM | `0x0000_0000` | 64 KB | Inferred ROM model (firmware image preload) |
| RAM | `0x1000_0000` | 64 KB | Inferred RAM model (byte-write data memory) |
| UART | `0x2000_0000` | 4 KB | UART MMIO registers |
| SPI | `0x2000_1000` | 4 KB | SPI MMIO registers |
| GPIO | `0x2000_2000` | 4 KB | GPIO MMIO registers |
| CMU | `0x2000_3000` | 4 KB | Clock management + clock gating control |

## Memory implementation note
- Current ROM/RAM are inferred memory wrappers for academic RTL verification.
- In enterprise ASIC flow, these wrappers are intended to be replaced with foundry memory macros.

## Peripheral register map (initial)

### UART (`0x2000_0000`)
- `0x00` TXDATA (W): write byte to transmit/debug print
- `0x04` STATUS (R): bit0 = tx_ready (always 1 in current model)

### SPI (`0x2000_1000`)
- `0x00` CTRL (RW): bit0=enable, bit1=irq_en, bit2=cpol, bit3=cpha, bit4=lsb_first, bit5=cs_en
- `0x04` DIV (RW): clock divider (lower 8 bits)
- `0x08` TXDATA (W/R): write starts transfer, read returns last TX byte
- `0x0C` RXDATA (R): last received byte
- `0x10` STATUS (RW1C): bit0=busy, bit1=rx_valid, bit2=irq_pending, bit3=cs_active

### GPIO (`0x2000_2000`)
- `0x00` DATA_OUT (RW)
- `0x04` DATA_IN (R)
- `0x08` DIR (RW): 1=output, 0=input
- `0x0C` TOGGLE (W): toggle selected output bits

### CMU (`0x2000_3000`)
- `0x00` CLK_EN (RW): bit0=UART, bit1=SPI, bit2=GPIO
- `0x04` CLK_STAT (R): latched enables (same as CLK_EN in this model)
