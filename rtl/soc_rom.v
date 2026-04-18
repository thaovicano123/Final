module soc_rom #(
    parameter MEMFILE    = "",
    parameter ADDR_WIDTH = 14
) (
    input  wire        valid,
    input  wire [31:0] addr,
    output wire        ready,
    output wire [31:0] rdata
);
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [31:0] mem [0:DEPTH-1];

    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    assign ready = valid;
    assign rdata = mem[word_addr];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h0000_0013; // NOP (addi x0, x0, 0)

        if (MEMFILE != "")
            $readmemh(MEMFILE, mem);
    end
endmodule
