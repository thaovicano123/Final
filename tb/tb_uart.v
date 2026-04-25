`timescale 1ns/1ps

module tb_uart;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire ready;
    wire [31:0] rdata;
    wire uart_tx;
    
    uart_mmio u_uart (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata),
        .uart_tx(uart_tx),
        .uart_rx(1'b1)
    );

    always #5 clk = ~clk;

    task bus_write;
        input [31:0] wr_addr;
        input [31:0] wr_data;
        begin
            valid = 1'b1;
            addr = wr_addr;
            wdata = wr_data;
            wstrb = 4'hF;
            @(posedge clk);
            valid = 1'b0;
            wstrb = 4'h0;
            @(posedge clk);
        end
    endtask

    task bus_read;
        input [31:0] rd_addr;
        output [31:0] rd_data;
        begin
            valid = 1'b1;
            addr = rd_addr;
            wstrb = 4'h0;
            @(posedge clk);
            rd_data = rdata;
            valid = 1'b0;
            wstrb = 4'h0;
            @(posedge clk);
        end
    endtask

    reg [31:0] rd;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;

        $dumpfile("results/phase3/tb_uart.vcd");
        $dumpvars(0, tb_uart);

        repeat (10) @(posedge clk);
        resetn = 1'b1;

        if (uart_tx !== 1'b1) begin
            $display("[FAIL] UART TX should idle high");
            $fatal(1);
        end

        bus_write(32'h2000_0000, 32'h0000_0041);
        bus_read(32'h2000_0000, rd);
        if (rd[7:0] !== 8'h41) begin
            $display("[FAIL] TXDATA readback mismatch: 0x%02x", rd[7:0]);
            $fatal(1);
        end

        bus_read(32'h2000_0004, rd);
        if (rd[0] !== 1'b1) begin
            $display("[FAIL] STATUS.tx_ready expected 1");
            $fatal(1);
        end

        bus_read(32'h2000_0008, rd);
        if (rd[0] !== 1'b1) begin
            $display("[FAIL] RX sample mismatch");
            $fatal(1);
        end

        bus_write(32'h2000_0000, 32'h0000_00DE);
        bus_read(32'h2000_0000, rd);
        if (rd[7:0] !== 8'hDE) begin
            $display("[FAIL] Final TXDATA mismatch");
            $fatal(1);
        end

        $display("\nUART TEST: ALL TESTS PASSED");
        $finish;
    end
endmodule