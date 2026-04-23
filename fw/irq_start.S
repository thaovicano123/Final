.section .init
.global _start

_start:
    j _boot

.section .text
.global _boot

_boot:
    la sp, _stack_top

    # Copy .data from ROM load address to RAM runtime address.
    la t0, _sidata
    la t1, _sdata
    la t2, _edata
1:
    beq t1, t2, 2f
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j 1b

    # Clear .bss section.
2:
    la t0, _sbss
    la t1, _ebss
3:
    beq t0, t1, 4f
    sw x0, 0(t0)
    addi t0, t0, 4
    j 3b

4:

    // PicoRV32 custom: maskirq x0, x0 (unmask all IRQs)
    .word 0x0600600b

    call main

halt:
    j halt

.section .irq, "ax", @progbits
.global irq_vec

irq_vec:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)

    // Toggle GPIO bit[8] to mark every IRQ service.
    li t0, 0x2000200c
    li t1, 0x00000100
    sw t1, 0(t0)

    // Clear timer pending (W1C).
    li t0, 0x2000100c
    li t1, 0x00000001
    sw t1, 0(t0)

    // Increment irq_count in RAM.
    la t0, irq_count
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    addi sp, sp, 16

    // PicoRV32 custom: retirq
    .word 0x0400000b
