`timescale 1ns/1ps

module tb_spi;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire ready;
    wire [31:0] rdata;
    wire irq;
    wire spi_sclk;
    wire spi_mosi;
    reg spi_miso;
    wire spi_cs_n;

    reg [31:0] rd;

    spi_mmio dut (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata),
        .irq(irq),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
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
            @(posedge clk);
            rd_data = rdata;
            valid = 1'b0;
            wstrb = 4'h0;
            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;
        spi_miso = 1'b0;

        $dumpfile("results/phase3/tb_spi.vcd");
        $dumpvars(0, tb_spi);

        repeat (10) @(posedge clk);
        resetn = 1'b1;
        repeat (10) @(posedge clk);

        if (spi_cs_n !== 1'b1) begin
            $display("[FAIL] CS should be deasserted after reset");
            $fatal(1);
        end

        // CTRL: en=1, irq_en=1, cpol=0, cpha=0, lsb_first=0, csen=1
        bus_write(32'h2000_1000, 32'h0000_0023);
        bus_write(32'h2000_1004, 32'h0000_0002);

        bus_read(32'h2000_1000, rd);
        if (rd[5:0] !== 6'b100011) begin
            $display("[FAIL] CTRL readback mismatch: 0x%08x", rd);
            $fatal(1);
        end

        bus_write(32'h2000_1008, 32'h0000_00A5);
        wait (irq === 1'b1);

        bus_read(32'h2000_1010, rd);
        if (rd[2] !== 1'b1) begin
            $display("[FAIL] STATUS.irq_pending expected high");
            $fatal(1);
        end

        bus_write(32'h2000_1010, 32'h0000_0004);
        bus_read(32'h2000_1010, rd);
        if (rd[2] !== 1'b0) begin
            $display("[FAIL] STATUS.irq_pending clear failed");
            $fatal(1);
        end

        bus_read(32'h2000_100C, rd);
        if (rd[7:0] !== 8'h00) begin
            $display("[FAIL] RXDATA expected 0x00 (MISO tied low), got 0x%02x", rd[7:0]);
            $fatal(1);
        end

        $display("\nSPI TEST: ALL TESTS PASSED");
        $finish;
    end
endmodule