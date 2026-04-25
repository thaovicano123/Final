`timescale 1ns/1ps

module tb_ram;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire ready;
    wire [31:0] rdata;

    soc_ram #(
        .ADDR_WIDTH(8),
        .INIT_ZERO(1)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;

        $dumpfile("results/phase3/tb_ram.vcd");
        $dumpvars(0, tb_ram);

        repeat (2) @(posedge clk);
        resetn = 1'b1;

        // Initial read should be zero
        valid = 1'b1;
        addr = 32'h0000_0000;
        wstrb = 4'h0;
        @(posedge clk);
        if (rdata !== 32'h0000_0000) begin
            $display("[FAIL] RAM init read mismatch: 0x%08x", rdata);
            $fatal(1);
        end

        // Full word write/read
        addr = 32'h0000_0004;
        wdata = 32'hDEAD_BEEF;
        wstrb = 4'hF;
        @(posedge clk);
        wstrb = 4'h0;
        @(posedge clk);
        if (rdata !== 32'hDEAD_BEEF) begin
            $display("[FAIL] RAM full-word write mismatch: 0x%08x", rdata);
            $fatal(1);
        end

        // Partial byte write on same word
        wdata = 32'h0000_00AA;
        wstrb = 4'h1;
        @(posedge clk);
        wstrb = 4'h0;
        @(posedge clk);
        if (rdata !== 32'hDEAD_BEAA) begin
            $display("[FAIL] RAM partial write mismatch: 0x%08x", rdata);
            $fatal(1);
        end

        valid = 1'b0;
        if (ready !== 1'b0) begin
            $display("[FAIL] RAM ready should follow valid");
            $fatal(1);
        end

        $display("RAM TEST: ALL TESTS PASSED");
        $finish;
    end
endmodule
