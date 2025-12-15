// ============================================================================
// IF/ID Pipeline Register
// Latches instruction and PC+4 from Fetch stage to Decode stage
// Supports stall (enable) and flush
// ============================================================================

module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,         // 0 = stall, 1 = update
    input  wire        flush,          // 1 = clear to NOP
    
    // Inputs from IF stage
    input  wire [31:0] instr_F,
    input  wire [31:0] pc_plus4_F,
    
    // Outputs to ID stage
    output reg  [31:0] instr_D,
    output reg  [31:0] pc_plus4_D,
    output reg         valid_D    // Valid instruction indicator
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_D   <= 32'b0;
            pc_plus4_D <= 32'b0;
            valid_D    <= 1'b0;
        end
        else if (flush) begin
            // Insert NOP (bubble) - all zeros
            instr_D   <= 32'b0;
            pc_plus4_D <= 32'b0;
            valid_D    <= 1'b0;
        end
        else if (enable) begin
            // Normal update
            instr_D   <= instr_F;
            pc_plus4_D <= pc_plus4_F;
            valid_D    <= 1'b1;
        end
        // If !enable (stall) and !flush, hold value
    end

endmodule
