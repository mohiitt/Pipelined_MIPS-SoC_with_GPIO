module alu (
    input  wire [3:0]  op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  shamt,
    output wire        zero,
    output reg  [31:0] y
);
    assign zero = (y == 32'b0);
    
    always @(*) begin
        case (op)
            4'b0000: y = a & b;               // AND
            4'b0001: y = a | b;               // OR
            4'b0010: y = a + b;               // ADD
            4'b0011: y = 32'b0;               // MULTU (no ALU action)
            4'b0100: y = 32'b0;               // MFHI (handled in datapath)
            4'b0101: y = 32'b0;               // MFLO (handled in datapath)
            4'b0110: y = a - b;               // SUB
            4'b0111: y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1000: y = b << shamt;          // SLL
            4'b1001: y = b >> shamt;          // SRL
            default: y = 32'b0;
        endcase
    end
endmodule
