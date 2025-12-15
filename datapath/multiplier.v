module multiplier (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [63:0] product
);
    assign product = a * b;
endmodule