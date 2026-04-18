module icg_cell (
    input  wire clk,
    input  wire resetn,
    input  wire en,
    input  wire test_en,
    output wire gclk
);
    reg en_latched;

    // Latch enable while clock is low to avoid glitches on gated clock.
    always @(negedge clk or negedge resetn) begin
        if (!resetn)
            en_latched <= 1'b0;
        else
            en_latched <= en | test_en;
    end

    assign gclk = clk & en_latched;
endmodule
