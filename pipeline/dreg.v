// ============================================================================
// D Register with Enable (for PC stalling in pipelined design)
// ============================================================================

module dreg # (parameter WIDTH = 32) (
        input  wire             clk,
        input  wire             rst,
        input  wire             en,         // Enable signal (1 = update, 0 = hold)
        input  wire [WIDTH-1:0] d,
        output reg  [WIDTH-1:0] q
    );

    always @ (posedge clk, posedge rst) begin
        if (rst)      q <= 0;
        else if (en)  q <= d;
        // else hold current value
    end
endmodule
