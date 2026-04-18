.section .init
.global _start

_start:
    la sp, _stack_top

    // PicoRV32 custom: maskirq x0, x0 (unmask all IRQs)
    .word 0x0600600b

    j main

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
