`timescale 1ns/1ps

module tb_cmu;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire ready;
    wire [31:0] rdata;
    wire gclk_uart;
    wire gclk_spi;
    wire gclk_gpio;
    wire [2:0] clk_en_state;
    
    integer test_step;
    integer uart_toggle_count;
    integer spi_toggle_count;
    integer gpio_toggle_count;
    reg last_gclk_uart;
    reg last_gclk_spi;
    reg last_gclk_gpio;
    
    cmu u_cmu (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata),
        .gclk_uart(gclk_uart),
        .gclk_spi(gclk_spi),
        .gclk_gpio(gclk_gpio),
        .clk_en_state(clk_en_state)
    );
    
    // Toggle counters for clock gating verification
    always @(posedge gclk_uart) begin
        if (resetn) uart_toggle_count = uart_toggle_count + 1;
    end
    
    always @(posedge gclk_spi) begin
        if (resetn) spi_toggle_count = spi_toggle_count + 1;
    end
    
    always @(posedge gclk_gpio) begin
        if (resetn) gpio_toggle_count = gpio_toggle_count + 1;
    end
    
    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;
        test_step = 0;
        uart_toggle_count = 0;
        spi_toggle_count = 0;
        gpio_toggle_count = 0;
        last_gclk_uart = 1'b0;
        last_gclk_spi = 1'b0;
        last_gclk_gpio = 1'b0;
        
        $dumpfile("results/phase3/tb_cmu.vcd");
        $dumpvars(0, tb_cmu);
        
        // Initialize
        repeat (10) @(posedge clk);
        resetn = 1'b1;
        repeat (10) @(posedge clk);
        
        // Test 1: Check reset state
        $display("Test 1: Checking reset state");
        if (clk_en_state !== 3'b111) begin
            $display("[FAIL] Clock enables should be all 1 after reset");
            $fatal(1);
        end else begin
            $display("[PASS] Clock enables are all 1 after reset");
        end
        
        // Test 2: Test reading clock enable register
        $display("\nTest 2: Test reading clock enable register");
        valid = 1'b1;
        addr = 32'h20003000;  // CMU base address
        wstrb = 4'h0;  // Read operation
        repeat (5) @(posedge clk);
        
        if (rdata[2:0] === 3'b111) begin
            $display("[PASS] Read clock enable register correctly returns 0x%08x", rdata);
        end else begin
            $display("[FAIL] Expected 0x00000007, got 0x%08x", rdata);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (5) @(posedge clk);
        
        // Test 3: Test enabling all clocks
        $display("\nTest 3: Test enabling all clocks");
        valid = 1'b1;
        addr = 32'h20003000;
        wdata = 32'h00000007;  // Enable all clocks
        wstrb = 4'hF;  // Write all bytes
        repeat (5) @(posedge clk);
        
        if (clk_en_state === 3'b111) begin
            $display("[PASS] All clocks enabled (111)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (20) @(posedge clk);  // Let clocks toggle
        
        // Check toggle counts
        if (uart_toggle_count > 0 && spi_toggle_count > 0 && gpio_toggle_count > 0) begin
            $display("[PASS] All clocks are toggling when enabled");
        end else begin
            $display("[FAIL] Some clocks are not toggling");
            $fatal(1);
        end
        
        // Test 4: Test disabling all clocks
        $display("\nTest 4: Test disabling all clocks");
        uart_toggle_count = 0;
        spi_toggle_count = 0;
        gpio_toggle_count = 0;
        
        valid = 1'b1;
        addr = 32'h20003000;
        wdata = 32'h00000000;  // Disable all clocks
        wstrb = 4'hF;
        repeat (5) @(posedge clk);
        
        if (clk_en_state === 3'b000) begin
            $display("[PASS] All clocks disabled (000)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (20) @(posedge clk);  // Check if clocks stop
        
        // Check toggle counts (should be minimal)
        if (uart_toggle_count < 3 && spi_toggle_count < 3 && gpio_toggle_count < 3) begin
            $display("[PASS] All clocks stopped when disabled");
        end else begin
            $display("[FAIL] Clocks are still toggling");
            $fatal(1);
        end
        
        // Test 5: Test enabling only GPIO
        $display("\nTest 5: Test enabling only GPIO");
        valid = 1'b1;
        addr = 32'h20003000;
        wdata = 32'h00000004;  // Enable only GPIO (bit 2)
        wstrb = 4'hF;
        repeat (5) @(posedge clk);
        
        if (clk_en_state === 3'b100) begin
            $display("[PASS] Only GPIO enabled (100)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (20) @(posedge clk);
        
        // Check which clocks are toggling
        if (uart_toggle_count < 3 && spi_toggle_count < 3 && gpio_toggle_count > 0) begin
            $display("[PASS] Only GPIO clock is toggling");
        end else begin
            $display("[FAIL] GPIO clock toggle count: %d", gpio_toggle_count);
            $fatal(1);
        end
        
        // Test 6: Test enabling only UART
        $display("\nTest 6: Test enabling only UART");
        uart_toggle_count = 0;
        spi_toggle_count = 0;
        gpio_toggle_count = 0;
        
        valid = 1'b1;
        addr = 32'h20003000;
        wdata = 32'h00000001;  // Enable only UART (bit 0)
        wstrb = 4'hF;
        repeat (5) @(posedge clk);
        
        if (clk_en_state === 3'b001) begin
            $display("[PASS] Only UART enabled (001)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (20) @(posedge clk);
        
        if (uart_toggle_count > 0 && spi_toggle_count < 3 && gpio_toggle_count < 3) begin
            $display("[PASS] Only UART clock is toggling");
        end else begin
            $display("[FAIL] UART clock toggle count: %d", uart_toggle_count);
            $fatal(1);
        end
        
        // Test 7: Test enabling only SPI
        $display("\nTest 7: Test enabling only SPI");
        uart_toggle_count = 0;
        spi_toggle_count = 0;
        gpio_toggle_count = 0;
        
        valid = 1'b1;
        addr = 32'h20003000;
        wdata = 32'h00000002;  // Enable only SPI (bit 1)
        wstrb = 4'hF;
        repeat (5) @(posedge clk);
        
        if (clk_en_state === 3'b010) begin
            $display("[PASS] Only SPI enabled (010)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (20) @(posedge clk);
        
        if (uart_toggle_count < 3 && spi_toggle_count > 0 && gpio_toggle_count < 3) begin
            $display("[PASS] Only SPI clock is toggling");
        end else begin
            $display("[FAIL] SPI clock toggle count: %d", spi_toggle_count);
            $fatal(1);
        end
        
        // Test 8: Test full write value 0x5 (UART + GPIO)
        $display("\nTest 8: Test partial write");
        valid = 1'b1;
        addr = 32'h20003000;
        wdata = 32'h00000005;  // Enable UART and GPIO
        wstrb = 4'hF;  // Write all bytes
        repeat (5) @(posedge clk);
        
        if (clk_en_state === 3'b101) begin
            $display("[PASS] UART and GPIO enabled (101)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        valid = 1'b0;
        repeat (20) @(posedge clk);
        
        // Test 9: Test reading back partial writes
        $display("\nTest 9: Test reading back");
        valid = 1'b1;
        addr = 32'h20003000;
        wstrb = 4'h0;  // Read operation
        repeat (5) @(posedge clk);
        
        if (rdata[2:0] === 3'b101) begin
            $display("[PASS] Read back correct clock enable state");
        end else begin
            $display("[FAIL] Expected 0x00000005, got 0x%08x", rdata);
            $fatal(1);
        end
        
        valid = 1'b0;
        
        $display("\nCMU TEST: ALL TESTS PASSED");
        $finish;
    end
    
    // Clock for simulation
    always #5 clk = ~clk;
endmodule