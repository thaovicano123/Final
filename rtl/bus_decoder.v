module bus_decoder (
    input  wire [31:0] addr,
    output wire        sel_rom,
    output wire        sel_ram,
    output wire        sel_uart,
    output wire        sel_spi,
    output wire        sel_gpio,
    output wire        sel_cmu,
    output wire        sel_none
);
    assign sel_rom   = (addr[31:16] == 16'h0000);   // 0x0000_0000 - 0x0000_FFFF
    assign sel_ram   = (addr[31:16] == 16'h1000);   // 0x1000_0000 - 0x1000_FFFF
    assign sel_uart  = (addr[31:12] == 20'h20000);  // 0x2000_0000 - 0x2000_0FFF
    assign sel_spi   = (addr[31:12] == 20'h20001);  // 0x2000_1000 - 0x2000_1FFF
    assign sel_gpio  = (addr[31:12] == 20'h20002);  // 0x2000_2000 - 0x2000_2FFF
    assign sel_cmu   = (addr[31:12] == 20'h20003);  // 0x2000_3000 - 0x2000_3FFF

    assign sel_none = !(sel_rom | sel_ram | sel_uart | sel_spi | sel_gpio | sel_cmu);
endmodule
