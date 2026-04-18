`timescale 1ns/1ps

module tb_phase2_mmio_irq_gating;
    reg clk;
    reg resetn;

    reg        bus_valid;
    reg [31:0] bus_addr;
    reg [31:0] bus_wdata;
    reg [3:0]  bus_wstrb;

    wire       bus_ready;
    wire [31:0] bus_rdata;

    wire sel_rom;
    wire sel_ram;
    wire sel_uart;
    wire sel_timer;
    wire sel_gpio;
    wire sel_cmu;
    wire sel_none;

    wire gclk_uart;
    wire gclk_timer;
    wire gclk_gpio;
    wire [2:0] clk_en_state;

    wire uart_ready;
    wire [31:0] uart_rdata;
    wire timer_ready;
    wire [31:0] timer_rdata;
    wire gpio_ready;
    wire [31:0] gpio_rdata;
    wire cmu_ready;
    wire [31:0] cmu_rdata;

    wire timer_irq;

    reg [31:0] gpio_in;
    wire [31:0] gpio_out;

    integer error_count;

    localparam UART_BASE  = 32'h2000_0000;
    localparam TIMER_BASE = 32'h2000_1000;
    localparam GPIO_BASE  = 32'h2000_2000;
    localparam CMU_BASE   = 32'h2000_3000;

    bus_decoder u_bus_decoder (
        .addr(bus_addr),
        .sel_rom(sel_rom),
        .sel_ram(sel_ram),
        .sel_uart(sel_uart),
        .sel_timer(sel_timer),
        .sel_gpio(sel_gpio),
        .sel_cmu(sel_cmu),
        .sel_none(sel_none)
    );

    assign bus_ready = (sel_uart  && uart_ready) |
                       (sel_timer && timer_ready) |
                       (sel_gpio  && gpio_ready) |
                       (sel_cmu   && cmu_ready) |
                       (sel_none  && bus_valid);

    assign bus_rdata = sel_uart  ? uart_rdata  :
                       sel_timer ? timer_rdata :
                       sel_gpio  ? gpio_rdata  :
                       sel_cmu   ? cmu_rdata   : 32'h0000_0000;

    cmu u_cmu (
        .clk(clk),
        .resetn(resetn),
        .valid(bus_valid && sel_cmu),
        .addr(bus_addr),
        .wdata(bus_wdata),
        .wstrb(bus_wstrb),
        .ready(cmu_ready),
        .rdata(cmu_rdata),
        .gclk_uart(gclk_uart),
        .gclk_timer(gclk_timer),
        .gclk_gpio(gclk_gpio),
        .clk_en_state(clk_en_state)
    );

    uart_mmio u_uart (
        .clk(gclk_uart),
        .resetn(resetn),
        .valid(bus_valid && sel_uart),
        .addr(bus_addr),
        .wdata(bus_wdata),
        .wstrb(bus_wstrb),
        .ready(uart_ready),
        .rdata(uart_rdata),
        .uart_tx(),
        .uart_rx(1'b1)
    );

    timer_mmio u_timer (
        .clk(gclk_timer),
        .resetn(resetn),
        .valid(bus_valid && sel_timer),
        .addr(bus_addr),
        .wdata(bus_wdata),
        .wstrb(bus_wstrb),
        .ready(timer_ready),
        .rdata(timer_rdata),
        .irq(timer_irq)
    );

    gpio_mmio u_gpio (
        .clk(gclk_gpio),
        .resetn(resetn),
        .valid(bus_valid && sel_gpio),
        .addr(bus_addr),
        .wdata(bus_wdata),
        .wstrb(bus_wstrb),
        .ready(gpio_ready),
        .rdata(gpio_rdata),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk;

    task automatic bus_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            bus_valid = 1'b1;
            bus_addr  = addr;
            bus_wdata = data;
            bus_wstrb = 4'hF;
            begin
                @(posedge clk);
                while (!bus_ready)
                    @(posedge clk);
            end
            @(negedge clk);
            bus_valid = 1'b0;
            bus_addr  = 32'h0;
            bus_wdata = 32'h0;
            bus_wstrb = 4'h0;
        end
    endtask

    task automatic bus_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            bus_valid = 1'b1;
            bus_addr  = addr;
            bus_wdata = 32'h0;
            bus_wstrb = 4'h0;
            begin
                @(posedge clk);
                while (!bus_ready)
                    @(posedge clk);
            end
            #1;
            data = bus_rdata;
            @(negedge clk);
            bus_valid = 1'b0;
            bus_addr  = 32'h0;
        end
    endtask

    task automatic expect_eq;
        input [31:0] got;
        input [31:0] exp;
        input [8*48-1:0] tag;
        begin
            if (got !== exp) begin
                $display("[FAIL] %0s got=0x%08x expected=0x%08x", tag, got, exp);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] %0s = 0x%08x", tag, got);
            end
        end
    endtask

    function automatic gclk_val;
        input [1:0] which;
        begin
            case (which)
                2'd0: gclk_val = gclk_uart;
                2'd1: gclk_val = gclk_timer;
                default: gclk_val = gclk_gpio;
            endcase
        end
    endfunction

    task automatic check_gclk_activity;
        input [1:0] which;
        input [31:0] cycles;
        input expect_toggle;
        input [8*48-1:0] tag;
        integer i;
        integer toggles;
        reg prev;
        begin
            toggles = 0;
            prev = gclk_val(which);
            for (i = 0; i < cycles; i = i + 1) begin
                @(posedge clk);
                if (gclk_val(which) != prev)
                    toggles = toggles + 1;
                prev = gclk_val(which);
                @(negedge clk);
                if (gclk_val(which) != prev)
                    toggles = toggles + 1;
                prev = gclk_val(which);
            end

            if (expect_toggle && toggles == 0) begin
                $display("[FAIL] %0s expected toggle but got 0", tag);
                error_count = error_count + 1;
            end else if (!expect_toggle && toggles > 1) begin
                $display("[FAIL] %0s expected no steady toggling but got %0d", tag, toggles);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] %0s toggle_count=%0d", tag, toggles);
            end
        end
    endtask

    task automatic test_mmio_gpio_uart;
        reg [31:0] r;
        begin
            $display("\n== Test MMIO: GPIO/UART ==");

            gpio_in = 32'hA5A5_5A5A;

            bus_write(GPIO_BASE + 32'h08, 32'h0000_00FF); // DIR
            bus_write(GPIO_BASE + 32'h00, 32'h0000_0055); // DATA_OUT
            bus_read(GPIO_BASE + 32'h00, r);
            expect_eq(r, 32'h0000_0055, "GPIO_DATA_OUT");

            bus_write(GPIO_BASE + 32'h0C, 32'h0000_000F); // TOGGLE
            bus_read(GPIO_BASE + 32'h00, r);
            expect_eq(r, 32'h0000_005A, "GPIO_TOGGLE");

            bus_read(GPIO_BASE + 32'h04, r);
            expect_eq(r, 32'hA5A5_5A5A, "GPIO_DATA_IN");

            bus_write(UART_BASE + 32'h00, 32'h0000_0041); // 'A'
            bus_read(UART_BASE + 32'h00, r);
            expect_eq(r, 32'h0000_0041, "UART_TXDATA_LOOPBACK");
        end
    endtask

    task automatic test_timer_irq;
        reg [31:0] r;
        integer i;
        reg irq_seen;
        begin
            $display("\n== Test Timer IRQ ==");

            // Enable only timer clock to prove isolated gating operation.
            bus_write(CMU_BASE + 32'h00, 32'h0000_0002);

            bus_write(TIMER_BASE + 32'h00, 32'd5); // LOAD
            bus_write(TIMER_BASE + 32'h04, 32'd3); // VALUE
            bus_write(TIMER_BASE + 32'h08, 32'h0000_0003); // enable + irq_en

            irq_seen = 1'b0;
            for (i = 0; i < 50; i = i + 1) begin
                @(posedge clk);
                if (timer_irq)
                    irq_seen = 1'b1;
            end

            if (!irq_seen) begin
                $display("[FAIL] TIMER_IRQ not asserted in timeout window");
                error_count = error_count + 1;
            end else begin
                $display("[PASS] TIMER_IRQ asserted");
            end

            bus_read(TIMER_BASE + 32'h0C, r);
            expect_eq(r[0], 32'h1, "TIMER_IRQ_STATUS_BIT");

            bus_write(TIMER_BASE + 32'h0C, 32'h0000_0001); // clear pending
            @(posedge clk);
            if (timer_irq) begin
                $display("[FAIL] TIMER_IRQ not cleared");
                error_count = error_count + 1;
            end else begin
                $display("[PASS] TIMER_IRQ cleared");
            end
        end
    endtask

    task automatic test_clock_gating;
        reg [31:0] r;
        begin
            $display("\n== Test Clock Gating ==");

            bus_read(CMU_BASE + 32'h00, r);
            expect_eq(r, 32'h0000_0007, "CMU_RESET_CLK_EN");

            check_gclk_activity(2'd0, 20, 1'b1, "GCLK_UART_INITIAL");
            check_gclk_activity(2'd1, 20, 1'b1, "GCLK_TIMER_INITIAL");
            check_gclk_activity(2'd2, 20, 1'b1, "GCLK_GPIO_INITIAL");

            bus_write(CMU_BASE + 32'h00, 32'h0000_0000);
            check_gclk_activity(2'd0, 20, 1'b0, "GCLK_UART_DISABLED");
            check_gclk_activity(2'd1, 20, 1'b0, "GCLK_TIMER_DISABLED");
            check_gclk_activity(2'd2, 20, 1'b0, "GCLK_GPIO_DISABLED");

            bus_write(CMU_BASE + 32'h00, 32'h0000_0005); // uart + gpio on
            check_gclk_activity(2'd0, 20, 1'b1, "GCLK_UART_REENABLED");
            check_gclk_activity(2'd1, 20, 1'b0, "GCLK_TIMER_STILL_OFF");
            check_gclk_activity(2'd2, 20, 1'b1, "GCLK_GPIO_REENABLED");
        end
    endtask

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        bus_valid = 1'b0;
        bus_addr  = 32'h0;
        bus_wdata = 32'h0;
        bus_wstrb = 4'h0;
        gpio_in = 32'h0;
        error_count = 0;

        $dumpfile("results/phase2/tb_phase2_mmio_irq_gating.vcd");
        $dumpvars(0, tb_phase2_mmio_irq_gating);

        repeat (5) @(posedge clk);
        resetn = 1'b1;
        repeat (4) @(posedge clk);

        test_clock_gating();

        // Re-enable all clocks for functional MMIO tests.
        bus_write(CMU_BASE + 32'h00, 32'h0000_0007);
        test_mmio_gpio_uart();
        test_timer_irq();

        if (error_count == 0) begin
            $display("\n========================================");
            $display("PHASE2 TESTBENCH RESULT: PASS");
            $display("========================================");
        end else begin
            $display("\n========================================");
            $display("PHASE2 TESTBENCH RESULT: FAIL (%0d errors)", error_count);
            $display("========================================");
            $fatal(1);
        end

        #50;
        $finish;
    end
endmodule
