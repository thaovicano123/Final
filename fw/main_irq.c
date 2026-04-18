#include <stdint.h>

#define UART_BASE   0x20000000u
#define TIMER_BASE  0x20001000u
#define GPIO_BASE   0x20002000u
#define CMU_BASE    0x20003000u

volatile uint32_t irq_count = 0;

static inline void mmio_write(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

static inline uint32_t mmio_read(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

static void uart_putc(char c)
{
    mmio_write(UART_BASE + 0x00u, (uint32_t)(uint8_t)c);
}

static void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s++);
    }
}

int main(void)
{
    volatile uint32_t i;

    // Enable all gated clocks.
    mmio_write(CMU_BASE + 0x00u, 0x00000007u);

    // GPIO bit0 and bit8 as outputs.
    mmio_write(GPIO_BASE + 0x08u, 0x00000101u);
    mmio_write(GPIO_BASE + 0x00u, 0x00000001u);

    uart_puts("Phase3 IRQ demo\n");

    // Timer periodic IRQ setup.
    mmio_write(TIMER_BASE + 0x00u, 50u);      // LOAD
    mmio_write(TIMER_BASE + 0x04u, 50u);      // VALUE
    mmio_write(TIMER_BASE + 0x0Cu, 1u);       // clear pending
    mmio_write(TIMER_BASE + 0x08u, 0x00000007u); // enable + irq_en + periodic

    while (1) {
        // Main loop toggles GPIO bit0 to show foreground progress.
        mmio_write(GPIO_BASE + 0x0Cu, 0x00000001u);
        for (i = 0; i < 500u; i++) {
            (void)mmio_read(GPIO_BASE + 0x04u);
        }
    }
}
