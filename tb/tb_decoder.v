`timescale 1ns/1ps

module tb_decoder;
    reg [31:0] addr;
    wire sel_rom;
    wire sel_ram;
    wire sel_uart;
    wire sel_spi;
    wire sel_gpio;
    wire sel_cmu;
    wire sel_none;
    
    reg [31:0] test_addr;
    
    bus_decoder u_bus_decoder (
        .addr(addr),
        .sel_rom(sel_rom),
        .sel_ram(sel_ram),
        .sel_uart(sel_uart),
        .sel_spi(sel_spi),
        .sel_gpio(sel_gpio),
        .sel_cmu(sel_cmu),
        .sel_none(sel_none)
    );
    
    initial begin
        addr = 32'h0;
        
        $dumpfile("results/phase3/tb_decoder.vcd");
        $dumpvars(0, tb_decoder);
        
        // Test 1: ROM address range (0x0000_0000 - 0x0FFF_FFFF)
        $display("Test 1: ROM address range");
        test_addr = 32'h00000000;
        addr = test_addr;
        #1;
        
        if (sel_rom && !sel_ram && !sel_uart && !sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] ROM selected for address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] ROM selection failed for address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 2: RAM address range (0x1000_0000 - 0x1FFF_FFFF)
        $display("\nTest 2: RAM address range");
        test_addr = 32'h10000000;
        addr = test_addr;
        #1;
        
        if (!sel_rom && sel_ram && !sel_uart && !sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] RAM selected for address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] RAM selection failed for address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 3: UART address (0x2000_0000)
        $display("\nTest 3: UART address");
        test_addr = 32'h20000000;
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && sel_uart && !sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] UART selected for address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] UART selection failed for address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 4: UART address offset (0x2000_0004)
        $display("\nTest 4: UART address offset");
        test_addr = 32'h20000004;
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && sel_uart && !sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] UART selected for offset address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] UART selection failed for offset address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 5: SPI address (0x2000_1000)
        $display("\nTest 5: SPI address");
        test_addr = 32'h20001000;
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] SPI selected for address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] SPI selection failed for address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 6: GPIO address (0x2000_2000)
        $display("\nTest 6: GPIO address");
        test_addr = 32'h20002000;
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_spi && sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] GPIO selected for address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] GPIO selection failed for address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 7: CMU address (0x2000_3000)
        $display("\nTest 7: CMU address");
        test_addr = 32'h20003000;
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_spi && !sel_gpio && sel_cmu && !sel_none) begin
            $display("[PASS] CMU selected for address 0x%08x", test_addr);
        end else begin
            $display("[FAIL] CMU selection failed for address 0x%08x", test_addr);
            $fatal(1);
        end
        
        // Test 8: Unknown address (should select sel_none)
        $display("\nTest 8: Unknown address");
        test_addr = 32'h30000000;
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_spi && !sel_gpio && !sel_cmu && sel_none) begin
            $display("[PASS] Unknown address correctly selects sel_none");
        end else begin
            $display("[FAIL] Unknown address handling failed");
            $fatal(1);
        end
        
        // Test 9: Boundary test - just below ROM range
        $display("\nTest 9: Boundary test - just below ROM range");
        test_addr = 32'h00000000 - 1;  // 0xFFFFFFFF
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_spi && !sel_gpio && !sel_cmu && sel_none) begin
            $display("[PASS] Address below ROM range correctly selects sel_none");
        end else begin
            $display("[FAIL] Boundary test failed");
            $fatal(1);
        end
        
        // Test 10: Boundary test - ROM upper bound (0x0000_FFFF)
        $display("\nTest 10: Boundary test - ROM upper bound");
        test_addr = 32'h0000FFFF;
        addr = test_addr;
        #1;
        
        if (sel_rom && !sel_ram && !sel_uart && !sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] ROM upper bound correctly selects ROM");
        end else begin
            $display("[FAIL] ROM upper bound test failed");
            $fatal(1);
        end
        
        // Test 11: Multiple addresses in same range
        $display("\nTest 11: Multiple addresses in same range");
        test_addr = 32'h20000010;  // UART offset
        addr = test_addr;
        #1;
        
        if (!sel_rom && !sel_ram && sel_uart && !sel_spi && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] UART offset address correctly selects UART");
        end else begin
            $display("[FAIL] UART offset test failed");
            $fatal(1);
        end
        
        $display("\nDECODER TEST: ALL TESTS PASSED");
        $finish;
    end
endmodule