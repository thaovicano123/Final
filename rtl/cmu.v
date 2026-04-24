module cmu (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output reg  [31:0] rdata,
    output wire        gclk_uart,
    output wire        gclk_spi,
    output wire        gclk_gpio,
    output wire [2:0]  clk_en_state
);
    reg [2:0] clk_en;

    wire wr_en = valid && (|wstrb);
    wire rd_en = valid && !(|wstrb);
    wire [3:0] reg_word = addr[5:2];

    assign ready = valid;
    assign clk_en_state = clk_en;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            clk_en <= 3'b111;
        end else if (wr_en) begin
            case (reg_word)
                4'h0: begin
                    if (wstrb[0])
                        clk_en <= wdata[2:0];
                end
                default: begin
                end
            endcase
        end
    end

    always @(*) begin
        rdata = 32'h0000_0000;
        if (rd_en) begin
            case (reg_word)
                4'h0: rdata = {29'd0, clk_en};
                4'h1: rdata = {29'd0, clk_en};
                default: rdata = 32'h0000_0000;
            endcase
        end
    end

    icg_cell u_icg_uart (
        .clk(clk),
        .resetn(resetn),
        .en(clk_en[0]),
        .test_en(1'b0),
        .gclk(gclk_uart)
    );

    icg_cell u_icg_spi (
        .clk(clk),
        .resetn(resetn),
        .en(clk_en[1]),
        .test_en(1'b0),
        .gclk(gclk_spi)
    );

    icg_cell u_icg_gpio (
        .clk(clk),
        .resetn(resetn),
        .en(clk_en[2]),
        .test_en(1'b0),
        .gclk(gclk_gpio)
    );
endmodule
