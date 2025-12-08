// ============================================================================
// Hazard Detection Unit for Pipelined MIPS
// Detects: Load-Use hazards, JR hazards, Branch hazards
// Generates: Stall signal and Flush signal
// ============================================================================

module hazard_unit (
    // Inputs from ID stage
    input  wire [4:0]  rs_D,           // Source register in ID stage
    input  wire [4:0]  rt_D,           // Target register in ID stage
    input  wire        branch_D,       // Branch instruction in ID
    input  wire        jump_reg_D,     // JR instruction in ID
    
    // Inputs from EX stage (ID/EX pipeline register)
    input  wire [4:0]  rt_E,           // Target register in EX stage
    input  wire [4:0]  write_reg_E,    // Write register in EX stage
    input  wire        we_reg_E,       // Register write enable in EX
    input  wire        dm2reg_E,       // Memory to register signal (LW in EX)
    
    // Inputs from MEM stage (EX/MEM pipeline register)
    input  wire [4:0]  write_reg_M,    // Write register in MEM stage
    input  wire        we_reg_M,       // Register write enable in MEM
    
    // Control outputs
    output wire        stall_F,        // Stall PC
    output wire        stall_D,        // Stall IF/ID register
    output wire        flush_E         // Flush ID/EX register (insert bubble)
);

    wire lw_stall;
    wire jr_stall;
    wire branch_stall;
    
    // ========================================================================
    // Load-Use Hazard Detection
    // A load instruction in EX stage has rt as destination
    // If current instruction in ID uses rt as source, we must stall
    // ========================================================================
    assign lw_stall = dm2reg_E && 
                      ((rt_E == rs_D) || (rt_E == rt_D));
    
    // ========================================================================
    // JR Hazard Detection
    // JR reads rs in ID stage for jump target
    // If rs is being written by instruction in EX or MEM, stall
    // ========================================================================
    assign jr_stall = jump_reg_D && 
                      ((we_reg_E && (write_reg_E != 5'b0) && (write_reg_E == rs_D)) ||
                       (we_reg_M && (write_reg_M != 5'b0) && (write_reg_M == rs_D)));
    
    // ========================================================================
    // Branch Hazard Detection
    // Branch compares rs and rt in ID stage
    // If either is being written by instruction in EX or MEM, stall
    // Note: For optimal performance, could add forwarding to ID instead
    // ========================================================================
    assign branch_stall = branch_D && 
                          ((we_reg_E && (write_reg_E != 5'b0) && 
                            ((write_reg_E == rs_D) || (write_reg_E == rt_D))) ||
                           (we_reg_M && (write_reg_M != 5'b0) && 
                            ((write_reg_M == rs_D) || (write_reg_M == rt_D))));
    
    // ========================================================================
    // Stall and Flush Logic
    // ========================================================================
    assign stall_F = lw_stall | jr_stall | branch_stall;
    assign stall_D = lw_stall | jr_stall | branch_stall;
    assign flush_E = lw_stall | jr_stall | branch_stall;

endmodule
