module soc_top_asic #(
    parameter MEMFILE = "",
    parameter ROM_ADDR_WIDTH = 8,
    parameter RAM_ADDR_WIDTH = 8
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        uart_rx,
    output wire        uart_tx,
    output wire        spi_sclk,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_cs_n,
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out
);
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    wire [31:0] irq;

    wire sel_rom;
    wire sel_ram;
    wire sel_uart;
    wire sel_spi;
    wire sel_gpio;
    wire sel_cmu;
    wire sel_none;

    wire rom_ready;
    wire [31:0] rom_rdata;
    wire ram_ready;
    wire [31:0] ram_rdata;
    wire uart_ready;
    wire [31:0] uart_rdata;
    wire spi_ready;
    wire [31:0] spi_rdata;
    wire gpio_ready;
    wire [31:0] gpio_rdata;
    wire cmu_ready;
    wire [31:0] cmu_rdata;

    wire gclk_uart;
    wire gclk_spi;
    wire gclk_gpio;
    wire [2:0] clk_en_state;
    wire spi_irq;

    assign irq = {31'd0, spi_irq};

    bus_decoder u_bus_decoder (
        .addr(mem_addr),
        .sel_rom(sel_rom),
        .sel_ram(sel_ram),
        .sel_uart(sel_uart),
        .sel_spi(sel_spi),
        .sel_gpio(sel_gpio),
        .sel_cmu(sel_cmu),
        .sel_none(sel_none)
    );

    assign mem_ready = (sel_rom   && rom_ready)  |
                       (sel_ram   && ram_ready)  |
                       (sel_uart  && uart_ready) |
                       (sel_spi   && spi_ready)  |
                       (sel_gpio  && gpio_ready) |
                       (sel_cmu   && cmu_ready)  |
                       (sel_none  && mem_valid);

    assign mem_rdata = sel_rom   ? rom_rdata  :
                       sel_ram   ? ram_rdata  :
                       sel_uart  ? uart_rdata :
                       sel_spi   ? spi_rdata  :
                       sel_gpio  ? gpio_rdata :
                       sel_cmu   ? cmu_rdata  : 32'h0000_0000;

    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .PROGADDR_IRQ  (32'h0000_0010),
        .ENABLE_IRQ    (1),
        .ENABLE_IRQ_QREGS(1)
    ) u_cpu (
        .clk      (clk),
        .resetn   (resetn),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr (mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .irq      (irq)
    );

    soc_rom #(
        .MEMFILE(MEMFILE),
        .ADDR_WIDTH(ROM_ADDR_WIDTH),
        .INIT_NOP(0)
    ) u_rom (
        .valid(mem_valid && sel_rom),
        .addr (mem_addr),
        .ready(rom_ready),
        .rdata(rom_rdata)
    );

    soc_ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .INIT_ZERO(0)
    ) u_ram (
        .clk  (clk),
        .resetn(resetn),
        .valid(mem_valid && sel_ram),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(ram_ready),
        .rdata(ram_rdata)
    );

    cmu u_cmu (
        .clk  (clk),
        .resetn(resetn),
        .valid(mem_valid && sel_cmu),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(cmu_ready),
        .rdata(cmu_rdata),
        .gclk_uart(gclk_uart),
        .gclk_spi(gclk_spi),
        .gclk_gpio(gclk_gpio),
        .clk_en_state(clk_en_state)
    );

    uart_mmio u_uart (
        .clk  (gclk_uart),
        .resetn(resetn),
        .valid(mem_valid && sel_uart),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(uart_ready),
        .rdata(uart_rdata),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    spi_mmio u_spi (
        .clk  (gclk_spi),
        .resetn(resetn),
        .valid(mem_valid && sel_spi),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(spi_ready),
        .rdata(spi_rdata),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        .irq  (spi_irq)
    );

    gpio_mmio u_gpio (
        .clk  (gclk_gpio),
        .resetn(resetn),
        .valid(mem_valid && sel_gpio),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(gpio_ready),
        .rdata(gpio_rdata),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );
endmodule
