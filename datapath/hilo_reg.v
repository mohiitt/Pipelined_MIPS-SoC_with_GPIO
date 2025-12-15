module hilo_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [63:0] product,
    output reg  [31:0] hi,
    output reg  [31:0] lo
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hi <= 32'b0;
            lo <= 32'b0;
        end else if (we) begin
            hi <= product[63:32];
            lo <= product[31:0];
        end
    end
endmodule