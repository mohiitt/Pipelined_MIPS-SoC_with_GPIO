// ============================================================================
// Forwarding Unit for Pipelined MIPS
// Generates forwarding control signals for ALU inputs A and B
// Forwards from EX/MEM stage (priority) or MEM/WB stage
// ============================================================================

module forwarding_unit (
    // Inputs from ID/EX pipeline register (EX stage)
    input  wire [4:0]  rs_E,           // Source register in EX stage
    input  wire [4:0]  rt_E,           // Target register in EX stage
    
    // Inputs from EX/MEM pipeline register (MEM stage)
    input  wire [4:0]  write_reg_M,    // Destination register in MEM stage
    input  wire        we_reg_M,       // Register write enable in MEM stage
    
    // Inputs from MEM/WB pipeline register (WB stage)
    input  wire [4:0]  write_reg_W,    // Destination register in WB stage
    input  wire        we_reg_W,       // Register write enable in WB stage
    
    // Forwarding control outputs
    output wire [1:0]  forward_A,      // Forwarding control for ALU input A
    output wire [1:0]  forward_B       // Forwarding control for ALU input B
);

    // ========================================================================
    // Forward A Logic
    // 00: Use value from register file (ID/EX.rd1)
    // 01: Forward from MEM/WB (WB result)
    // 10: Forward from EX/MEM (MEM stage ALU result)
    // ========================================================================
    reg [1:0] forward_A_sel;
    
    always @(*) begin
        // Default: no forwarding
        forward_A_sel = 2'b00;
        
        // Priority 1: Forward from EX/MEM (MEM stage)
        // This handles the case where the immediately preceding instruction
        // writes to the register we need
        if (we_reg_M && (write_reg_M != 5'b0) && (write_reg_M == rs_E)) begin
            forward_A_sel = 2'b10;
        end
        // Priority 2: Forward from MEM/WB (WB stage)
        // This handles the case where an earlier instruction writes to
        // the register we need (no conflict with MEM stage)
        else if (we_reg_W && (write_reg_W != 5'b0) && (write_reg_W == rs_E)) begin
            forward_A_sel = 2'b01;
        end
    end
    
    assign forward_A = forward_A_sel;
    
    // ========================================================================
    // Forward B Logic
    // 00: Use value from register file (ID/EX.rd2)
    // 01: Forward from MEM/WB (WB result)
    // 10: Forward from EX/MEM (MEM stage ALU result)
    // ========================================================================
    reg [1:0] forward_B_sel;
    
    always @(*) begin
        // Default: no forwarding
        forward_B_sel = 2'b00;
        
        // Priority 1: Forward from EX/MEM (MEM stage)
        if (we_reg_M && (write_reg_M != 5'b0) && (write_reg_M == rt_E)) begin
            forward_B_sel = 2'b10;
        end
        // Priority 2: Forward from MEM/WB (WB stage)
        else if (we_reg_W && (write_reg_W != 5'b0) && (write_reg_W == rt_E)) begin
            forward_B_sel = 2'b01;
        end
    end
    
    assign forward_B = forward_B_sel;

endmodule
