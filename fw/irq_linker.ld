OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 64K
}

SECTIONS
{
  . = ORIGIN(ROM);

  .init 0x00000000 : {
    KEEP(*(.init))
  } > ROM

  .irq 0x00000010 : {
    KEEP(*(.irq))
  } > ROM

  .text : ALIGN(16) {
    *(.text*)
    *(.rodata*)
  } > ROM

  .data : {
    *(.data*)
  } > RAM AT > ROM

  .bss : {
    *(.bss*)
    *(COMMON)
  } > RAM

  . = ALIGN(16);
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
