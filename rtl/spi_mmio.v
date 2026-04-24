module spi_mmio (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output reg  [31:0] rdata,
    output wire        spi_sclk,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_cs_n,
    output wire        irq
);
    reg [31:0] ctrl_reg;
    reg [31:0] div_reg;
    reg [7:0]  tx_reg;
    reg [7:0]  tx_shift;
    reg [7:0]  rx_shift;
    reg [2:0]  bit_count;
    reg [7:0]  div_cnt;
    reg        busy;
    reg        irq_pending;
    reg        rx_valid;
    reg        sclk_int;
    reg        cs_active;

    wire wr_en = valid && (|wstrb);
    wire rd_en = valid && !(|wstrb);
    wire [3:0] reg_word = addr[5:2];

    wire enable    = ctrl_reg[0];
    wire irq_en    = ctrl_reg[1];
    wire cpol      = ctrl_reg[2];
    wire cpha      = ctrl_reg[3];
    wire lsb_first = ctrl_reg[4];
    wire cs_en     = ctrl_reg[5];

    assign ready = valid;
    assign irq = irq_pending & irq_en;

    assign spi_sclk = sclk_int;
    assign spi_cs_n = ~(cs_active & cs_en);
    assign spi_mosi = lsb_first ? tx_shift[0] : tx_shift[7];

    function [31:0] apply_wstrb;
        input [31:0] old_val;
        input [31:0] new_val;
        input [3:0]  be;
        begin
            apply_wstrb = old_val;
            if (be[0]) apply_wstrb[7:0]   = new_val[7:0];
            if (be[1]) apply_wstrb[15:8]  = new_val[15:8];
            if (be[2]) apply_wstrb[23:16] = new_val[23:16];
            if (be[3]) apply_wstrb[31:24] = new_val[31:24];
        end
    endfunction

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            ctrl_reg    <= 32'h0000_0000;
            div_reg     <= 32'h0000_0004;
            tx_reg      <= 8'h00;
            tx_shift    <= 8'h00;
            rx_shift    <= 8'h00;
            bit_count   <= 3'd0;
            div_cnt     <= 8'd0;
            busy        <= 1'b0;
            irq_pending <= 1'b0;
            rx_valid    <= 1'b0;
            sclk_int    <= 1'b0;
            cs_active   <= 1'b0;
        end else begin
            if (wr_en) begin
                case (reg_word)
                    4'h0: ctrl_reg <= apply_wstrb(ctrl_reg, wdata, wstrb);
                    4'h1: div_reg  <= apply_wstrb(div_reg, wdata, wstrb);
                    4'h2: begin
                        if (enable && !busy) begin
                            tx_reg    <= wdata[7:0];
                            tx_shift  <= wdata[7:0];
                            rx_shift  <= 8'h00;
                            bit_count <= 3'd0;
                            div_cnt   <= 8'd0;
                            busy      <= 1'b1;
                            cs_active <= 1'b1;
                            sclk_int  <= cpol;
                            irq_pending <= 1'b0;
                            rx_valid  <= 1'b0;
                        end
                    end
                    4'h4: begin
                        if (wstrb[0]) begin
                            if (wdata[1]) rx_valid <= 1'b0;
                            if (wdata[2]) irq_pending <= 1'b0;
                        end
                    end
                    default: begin
                    end
                endcase
            end

            if (!enable) begin
                busy      <= 1'b0;
                cs_active <= 1'b0;
                sclk_int  <= cpol;
            end else if (busy) begin
                if (div_cnt >= div_reg[7:0]) begin
                    div_cnt <= 8'd0;
                    sclk_int <= ~sclk_int;

                    if ((cpha == 1'b0 && (~sclk_int) == ~cpol) ||
                        (cpha == 1'b1 && (~sclk_int) == cpol)) begin
                        if (lsb_first) begin
                            rx_shift <= {spi_miso, rx_shift[7:1]};
                            tx_shift <= {1'b0, tx_shift[7:1]};
                        end else begin
                            rx_shift <= {rx_shift[6:0], spi_miso};
                            tx_shift <= {tx_shift[6:0], 1'b0};
                        end

                        if (bit_count == 3'd7) begin
                            busy      <= 1'b0;
                            cs_active <= 1'b0;
                            sclk_int  <= cpol;
                            rx_valid  <= 1'b1;
                            irq_pending <= 1'b1;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end
                end else begin
                    div_cnt <= div_cnt + 8'd1;
                end
            end
        end
    end

    always @(*) begin
        rdata = 32'h0000_0000;
        if (rd_en) begin
            case (reg_word)
                4'h0: rdata = ctrl_reg;
                4'h1: rdata = div_reg;
                4'h2: rdata = {24'h0, tx_reg};
                4'h3: rdata = {24'h0, rx_shift};
                4'h4: rdata = {28'h0, cs_active, irq_pending, rx_valid, busy};
                default: rdata = 32'h0000_0000;
            endcase
        end
    end
endmodule
