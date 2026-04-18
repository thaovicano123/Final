.section .init
.global _start

_start:
    la sp, _stack_top
    call main

halt:
    j halt
