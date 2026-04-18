#include <stdint.h>

#define UART_BASE   0x20000000u
#define TIMER_BASE  0x20001000u
#define GPIO_BASE   0x20002000u
#define CMU_BASE    0x20003000u

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

    // Enable all peripheral gated clocks.
    mmio_write(CMU_BASE + 0x00u, 0x00000007u);

    uart_puts("SoC Phase2 CPU smoke\n");

    // GPIO[7:0] output, initial pattern.
    mmio_write(GPIO_BASE + 0x08u, 0x000000FFu);
    mmio_write(GPIO_BASE + 0x00u, 0x00000055u);

    // Configure timer but keep irq disabled in this smoke firmware.
    mmio_write(TIMER_BASE + 0x00u, 500u);
    mmio_write(TIMER_BASE + 0x04u, 500u);
    mmio_write(TIMER_BASE + 0x08u, 0x00000001u); // enable only

    while (1) {
        mmio_write(GPIO_BASE + 0x0Cu, 0x000000FFu); // toggle low byte
        uart_putc('.');
        for (i = 0; i < 2000u; i++) {
            (void)mmio_read(GPIO_BASE + 0x04u);
        }
    }
}
