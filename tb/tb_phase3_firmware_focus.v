`timescale 1ns/1ps

module tb_phase3_firmware_focus;
    reg clk;
    reg resetn;
    reg uart_rx;
    reg [31:0] gpio_in;
    wire uart_tx;
    wire [31:0] gpio_out;

    integer cycles;
    integer gpio_fg_toggles;
    integer gpio_bg_toggles;
    integer irq_count_increase_events;
    integer irq_count_final;
    integer irq_count_prev;
    integer fail_count;

    reg last_gpio0;
    reg last_gpio8;

    soc_top #(
        .MEMFILE("fw/firmware_irq.hex")
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk;

    task check_eq;
        input [255:0] name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=0x%08x exp=0x%08x", name, got, exp);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s = 0x%08x", name, got);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        uart_rx = 1'b1;
        gpio_in = 32'hCAFE_BABE;

        cycles = 0;
        gpio_fg_toggles = 0;
        gpio_bg_toggles = 0;
        irq_count_increase_events = 0;
        irq_count_final = 0;
        irq_count_prev = 0;
        fail_count = 0;

        last_gpio0 = 1'b0;
        last_gpio8 = 1'b0;

        $dumpfile("results/phase3/tb_phase3_firmware_focus.vcd");
        $dumpvars(0, tb_phase3_firmware_focus);

        repeat (8) @(posedge clk);
        resetn = 1'b1;

        // Let firmware complete MMIO setup sequence.
        repeat (3000) @(posedge clk);

        check_eq("TIMER_LOAD", dut.u_timer.load_reg, 32'd2000);
        check_eq("TIMER_CTRL", {29'd0, dut.u_timer.ctrl_reg}, 32'h0000_0007);
        check_eq("GPIO_DIR", dut.u_gpio.dir_reg, 32'h0000_0101);

        last_gpio0 = gpio_out[0];
        last_gpio8 = gpio_out[8];
        irq_count_prev = dut.u_ram.mem[0];

        repeat (180000) begin
            @(posedge clk);
            cycles = cycles + 1;

            if (gpio_out[0] != last_gpio0)
                gpio_fg_toggles = gpio_fg_toggles + 1;
            if (gpio_out[8] != last_gpio8)
                gpio_bg_toggles = gpio_bg_toggles + 1;

            last_gpio0 = gpio_out[0];
            last_gpio8 = gpio_out[8];

            irq_count_final = dut.u_ram.mem[0];
            if (irq_count_final > irq_count_prev)
                irq_count_increase_events = irq_count_increase_events + 1;
            irq_count_prev = irq_count_final;
        end

        if (gpio_fg_toggles < 8) begin
            $display("[FAIL] Foreground GPIO bit0 toggles too low: %0d", gpio_fg_toggles);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] Foreground GPIO bit0 toggles: %0d", gpio_fg_toggles);
        end

        if (gpio_bg_toggles < 5) begin
            $display("[FAIL] Background IRQ GPIO bit8 toggles too low: %0d", gpio_bg_toggles);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] Background IRQ GPIO bit8 toggles: %0d", gpio_bg_toggles);
        end

        if (irq_count_final < 5) begin
            $display("[FAIL] irq_count final too low: %0d", irq_count_final);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] irq_count final: %0d", irq_count_final);
        end

        if (irq_count_increase_events < 5) begin
            $display("[FAIL] irq_count increase events too low: %0d", irq_count_increase_events);
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] irq_count increase events: %0d", irq_count_increase_events);
        end

        if (fail_count != 0) begin
            $display("PHASE3_FIRMWARE_FOCUS: FAIL (%0d checks failed)", fail_count);
            $fatal(1);
        end else begin
            $display("PHASE3_FIRMWARE_FOCUS: PASS");
        end

        $finish;
    end
endmodule
