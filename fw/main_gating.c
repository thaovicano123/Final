#include <stdint.h>

#define SPI_BASE    0x20001000u
#define GPIO_BASE   0x20002000u
#define CMU_BASE    0x20003000u

#define CMU_CLK_EN    0x00u

#define GPIO_DATA_OUT 0x00u
#define GPIO_DATA_IN  0x04u
#define GPIO_DIR      0x08u
#define GPIO_TOGGLE   0x0Cu

#define SPI_CTRL      0x00u
#define SPI_DIV       0x04u
#define SPI_TXDATA    0x08u

static inline void mmio_write(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

static inline uint32_t mmio_read(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

static void busy_delay(volatile uint32_t count)
{
    volatile uint32_t i;
    for (i = 0; i < count; i++) {
        (void)mmio_read(GPIO_BASE + GPIO_DATA_IN);
    }
}

int main(void)
{
    volatile uint32_t i;

    // Phase A: enable all gated clocks.
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000007u);

    // Configure GPIO bit0 output and keep SPI idle until transfers start.
    mmio_write(GPIO_BASE + GPIO_DIR, 0x00000001u);
    mmio_write(GPIO_BASE + GPIO_DATA_OUT, 0x00000000u);
    mmio_write(SPI_BASE + SPI_DIV, 2u);
    mmio_write(SPI_BASE + SPI_CTRL, 0x00000021u); // enable + cs_en

    for (i = 0; i < 24u; i++) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        mmio_write(SPI_BASE + SPI_TXDATA, 0x000000A5u);
        busy_delay(40u);
    }

    // Phase B: disable all peripheral clocks.
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000000u);
    busy_delay(3500u);

    // Phase C: re-enable only GPIO clock.
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000004u);
    for (i = 0; i < 24u; i++) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        busy_delay(40u);
    }

    while (1) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        busy_delay(500u);
    }
}
