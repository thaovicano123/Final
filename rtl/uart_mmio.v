module uart_mmio (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output reg  [31:0] rdata,
    output wire        uart_tx,
    input  wire        uart_rx
);
    reg [7:0] tx_last;

    wire wr_en = valid && (|wstrb);
    wire rd_en = valid && !(|wstrb);
    wire [3:0] reg_word = addr[5:2];

    assign ready = valid;
    assign uart_tx = 1'b1;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx_last <= 8'h00;
        end else if (wr_en && reg_word == 4'h0) begin
            tx_last <= wdata[7:0];
            // Simulation aid: print UART payload to console.
            $write("%c", wdata[7:0]);
        end
    end

    always @(*) begin
        rdata = 32'h0000_0000;
        if (rd_en) begin
            case (reg_word)
                4'h0: rdata = {24'h0, tx_last};
                4'h1: rdata = 32'h0000_0001; // tx_ready
                4'h2: rdata = {31'h0, uart_rx};
                default: rdata = 32'h0000_0000;
            endcase
        end
    end
endmodule
