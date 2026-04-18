module gpio_mmio (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output reg  [31:0] rdata,
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out
);
    reg [31:0] data_out_reg;
    reg [31:0] dir_reg;

    wire wr_en = valid && (|wstrb);
    wire rd_en = valid && !(|wstrb);
    wire [3:0] reg_word = addr[5:2];

    assign ready = valid;
    assign gpio_out = data_out_reg & dir_reg;

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
            data_out_reg <= 32'h0000_0000;
            dir_reg      <= 32'h0000_0000;
        end else if (wr_en) begin
            case (reg_word)
                4'h0: data_out_reg <= apply_wstrb(data_out_reg, wdata, wstrb);
                4'h2: dir_reg      <= apply_wstrb(dir_reg, wdata, wstrb);
                4'h3: data_out_reg <= data_out_reg ^ apply_wstrb(32'h0000_0000, wdata, wstrb);
                default: begin
                end
            endcase
        end
    end

    always @(*) begin
        rdata = 32'h0000_0000;
        if (rd_en) begin
            case (reg_word)
                4'h0: rdata = data_out_reg;
                4'h1: rdata = gpio_in;
                4'h2: rdata = dir_reg;
                default: rdata = 32'h0000_0000;
            endcase
        end
    end
endmodule
