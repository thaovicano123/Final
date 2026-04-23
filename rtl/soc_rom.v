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
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [31:0] mem [0:DEPTH-1];

    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    assign ready = valid;
    assign rdata = mem[word_addr];

    // Inferred ROM model for academic/project use.
    // This wrapper can be replaced by a foundry ROM macro in ASIC flow.
    integer i;
    initial begin
        if (INIT_NOP) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] = 32'h0000_0013; // NOP (addi x0, x0, 0)
        end

        if (MEMFILE != "")
            $readmemh(MEMFILE, mem);
    end
endmodule
