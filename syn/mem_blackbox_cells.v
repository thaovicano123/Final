(* blackbox *)
module soc_rom #(
    parameter MEMFILE    = "",
    parameter ADDR_WIDTH = 14,
    parameter INIT_NOP   = 1
) (
    input  wire        valid,
    input  wire [31:0] addr,
    output wire        ready,
    output wire [31:0] rdata
);
endmodule

(* blackbox *)
module soc_ram #(
    parameter ADDR_WIDTH = 14,
    parameter INIT_ZERO  = 1
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output wire [31:0] rdata
);
endmodule
