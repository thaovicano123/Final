#include <stdint.h>

#define UART_BASE   0x20000000u
#define SPI_BASE    0x20001000u
#define GPIO_BASE   0x20002000u
#define CMU_BASE    0x20003000u

#define UART_TXDATA   0x00u

#define SPI_CTRL      0x00u
#define SPI_DIV       0x04u
#define SPI_TXDATA    0x08u

#define GPIO_DATA_OUT 0x00u
#define GPIO_DATA_IN  0x04u
#define GPIO_DIR      0x08u
#define GPIO_TOGGLE   0x0Cu

#define CMU_CLK_EN    0x00u

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
    mmio_write(UART_BASE + UART_TXDATA, (uint32_t)(uint8_t)c);
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

    // Enable all peripheral gated clocks: UART, SPI, GPIO.
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000007u);

    uart_puts("Phase3 firmware smoke\n");

    // GPIO[7:0] output, initial pattern.
    mmio_write(GPIO_BASE + GPIO_DIR, 0x000000FFu);
    mmio_write(GPIO_BASE + GPIO_DATA_OUT, 0x00000055u);

    // Configure SPI master (enable + CS enable), no IRQ in smoke firmware.
    mmio_write(SPI_BASE + SPI_DIV, 2u);
    mmio_write(SPI_BASE + SPI_CTRL, 0x00000021u);

    while (1) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x000000FFu); // toggle low byte
        uart_putc('.');
        mmio_write(SPI_BASE + SPI_TXDATA, 0x000000A5u);
        for (i = 0; i < 2000u; i++) {
            (void)mmio_read(GPIO_BASE + GPIO_DATA_IN);
        }
    }
}
