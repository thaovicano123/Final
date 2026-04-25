`timescale 1ns/1ps

module tb_rom;
    reg valid;
    reg [31:0] addr;
    wire ready;
    wire [31:0] rdata;

    soc_rom #(
        .ADDR_WIDTH(8),
        .INIT_NOP(1)
    ) dut (
        .valid(valid),
        .addr(addr),
        .ready(ready),
        .rdata(rdata)
    );

    initial begin
        valid = 1'b0;
        addr = 32'h0;

        $dumpfile("results/phase3/tb_rom.vcd");
        $dumpvars(0, tb_rom);

        // Read word 0
        valid = 1'b1;
        addr = 32'h0000_0000;
        #1;
        if (ready !== 1'b1) begin
            $display("[FAIL] ROM ready should follow valid");
            $fatal(1);
        end
        if (rdata !== 32'h0000_0013) begin
            $display("[FAIL] ROM default word mismatch at addr 0: 0x%08x", rdata);
            $fatal(1);
        end

        // Read another address
        addr = 32'h0000_0010;
        #1;
        if (rdata !== 32'h0000_0013) begin
            $display("[FAIL] ROM default word mismatch at addr 0x10: 0x%08x", rdata);
            $fatal(1);
        end

        valid = 1'b0;
        #1;
        if (ready !== 1'b0) begin
            $display("[FAIL] ROM ready should be low when valid is low");
            $fatal(1);
        end

        $display("ROM TEST: ALL TESTS PASSED");
        $finish;
    end
endmodule
