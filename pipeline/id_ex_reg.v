// ============================================================================
// ID/EX Pipeline Register
// Latches control signals, register values, and decoded instruction fields
// from Decode stage to Execute stage
// Supports flush (for hazards and control flow changes)
// ============================================================================

module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,          // 1 = clear all control signals
    
    // Control signals from ID stage
    input  wire        reg_dst_D,
    input  wire        alu_src_D,
    input  wire [3:0]  alu_ctrl_D,
    input  wire        we_dm_D,
    input  wire        dm2reg_D,
    input  wire        we_reg_D,
    input  wire        hilo_wd_D,
    input  wire [1:0]  hilo_mux_ctrl_D,
    
    // Data from ID stage
    input  wire [31:0] rd1_D,          // Register read data 1
    input  wire [31:0] rd2_D,          // Register read data 2
    input  wire [4:0]  rs_D,           // Source register address
    input  wire [4:0]  rt_D,           // Target register address
    input  wire [4:0]  rd_D,           // Destination register address
    input  wire [31:0] sext_imm_D,     // Sign-extended immediate
    input  wire [4:0]  shamt_D,        // Shift amount
    input  wire [31:0] pc_plus4_D,     // PC+4 for JAL
    
    // Outputs to EX stage
    output reg         reg_dst_E,
    output reg         alu_src_E,
    output reg  [3:0]  alu_ctrl_E,
    output reg         we_dm_E,
    output reg         dm2reg_E,
    output reg         we_reg_E,
    output reg         hilo_wd_E,
    output reg  [1:0]  hilo_mux_ctrl_E,
    
    output reg  [31:0] rd1_E,
    output reg  [31:0] rd2_E,
    output reg  [4:0]  rs_E,
    output reg  [4:0]  rt_E,
    output reg  [4:0]  rd_E,
    output reg  [31:0] sext_imm_E,
    output reg  [4:0]  shamt_E,
    output reg  [31:0] pc_plus4_E
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all control signals
            reg_dst_E      <= 1'b0;
            alu_src_E      <= 1'b0;
            alu_ctrl_E     <= 4'b0;
            we_dm_E        <= 1'b0;
            dm2reg_E       <= 1'b0;
            we_reg_E       <= 1'b0;
            hilo_wd_E      <= 1'b0;
            hilo_mux_ctrl_E <= 2'b0;
            
            // Reset data
            rd1_E          <= 32'b0;
            rd2_E          <= 32'b0;
            rs_E           <= 5'b0;
            rt_E           <= 5'b0;
            rd_E           <= 5'b0;
            sext_imm_E     <= 32'b0;
            shamt_E        <= 5'b0;
            pc_plus4_E     <= 32'b0;
        end
        else if (flush) begin
            // Insert bubble - clear control signals only
            reg_dst_E      <= 1'b0;
            alu_src_E      <= 1'b0;
            alu_ctrl_E     <= 4'b0;
            we_dm_E        <= 1'b0;
            dm2reg_E       <= 1'b0;
            we_reg_E       <= 1'b0;
            hilo_wd_E      <= 1'b0;
            hilo_mux_ctrl_E <= 2'b0;
            
            // Keep data (though it won't be used)
            rd1_E          <= rd1_D;
            rd2_E          <= rd2_D;
            rs_E           <= rs_D;
            rt_E           <= rt_D;
            rd_E           <= rd_D;
            sext_imm_E     <= sext_imm_D;
            shamt_E        <= shamt_D;
            pc_plus4_E     <= pc_plus4_D;
        end
        else begin
            // Normal operation
            reg_dst_E      <= reg_dst_D;
            alu_src_E      <= alu_src_D;
            alu_ctrl_E     <= alu_ctrl_D;
            we_dm_E        <= we_dm_D;
            dm2reg_E       <= dm2reg_D;
            we_reg_E       <= we_reg_D;
            hilo_wd_E      <= hilo_wd_D;
            hilo_mux_ctrl_E <= hilo_mux_ctrl_D;
            
            rd1_E          <= rd1_D;
            rd2_E          <= rd2_D;
            rs_E           <= rs_D;
            rt_E           <= rt_D;
            rd_E           <= rd_D;
            sext_imm_E     <= sext_imm_D;
            shamt_E        <= shamt_D;
            pc_plus4_E     <= pc_plus4_D;
        end
    end

endmodule
