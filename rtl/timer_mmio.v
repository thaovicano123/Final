module timer_mmio (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output reg  [31:0] rdata,
    output wire        irq
);
    reg [31:0] load_reg;
    reg [31:0] value_reg;
    reg [2:0]  ctrl_reg;    // [0]=enable, [1]=irq_en, [2]=periodic
    reg        irq_pending;

    wire wr_en = valid && (|wstrb);
    wire rd_en = valid && !(|wstrb);
    wire [3:0] reg_word = addr[5:2];
    wire [31:0] ctrl_wr_data;

    assign ready = valid;
    assign irq = irq_pending & ctrl_reg[1];
    assign ctrl_wr_data = apply_wstrb({29'h0, ctrl_reg}, wdata, wstrb);

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
            load_reg    <= 32'd1000;
            value_reg   <= 32'd1000;
            ctrl_reg    <= 3'b000;
            irq_pending <= 1'b0;
        end else begin
            if (wr_en) begin
                case (reg_word)
                    4'h0: load_reg  <= apply_wstrb(load_reg, wdata, wstrb);
                    4'h1: value_reg <= apply_wstrb(value_reg, wdata, wstrb);
                    4'h2: ctrl_reg  <= ctrl_wr_data[2:0];
                    4'h3: if (wdata[0] && wstrb[0]) irq_pending <= 1'b0; // W1C
                    default: begin
                    end
                endcase
            end

            if (ctrl_reg[0]) begin
                if (value_reg == 32'd0) begin
                    irq_pending <= 1'b1;
                    if (ctrl_reg[2])
                        value_reg <= load_reg;
                    else
                        ctrl_reg[0] <= 1'b0;
                end else begin
                    value_reg <= value_reg - 32'd1;
                end
            end
        end
    end

    always @(*) begin
        rdata = 32'h0000_0000;
        if (rd_en) begin
            case (reg_word)
                4'h0: rdata = load_reg;
                4'h1: rdata = value_reg;
                4'h2: rdata = {29'h0, ctrl_reg};
                4'h3: rdata = {31'h0, irq_pending};
                default: rdata = 32'h0000_0000;
            endcase
        end
    end
endmodule
