// ============================================================================
// EX/MEM Pipeline Register
// Latches ALU results, memory control signals, and write-back information
// from Execute stage to Memory stage
// ============================================================================

module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
    
    // Control signals from EX stage
    input  wire        we_dm_E,
    input  wire        dm2reg_E,
    input  wire        we_reg_E,
    input  wire        hilo_wd_E,
    input  wire [1:0]  hilo_mux_ctrl_E,
    input  wire        jal_E, // Add jal_E input
    
    // Data from EX stage
    input  wire [31:0] alu_out_E,      // ALU result
    input  wire [31:0] wd_dm_E,        // Data to write to memory
    input  wire [4:0]  write_reg_E,    // Destination register address
    input  wire [31:0] pc_plus4_E,     // PC+4 for JAL
    input  wire [63:0] mult_product_E, // Multiplier output
    
    // Outputs to MEM stage
    output reg         we_dm_M,
    output reg         dm2reg_M,
    output reg         we_reg_M,
    output reg         hilo_wd_M,
    output reg  [1:0]  hilo_mux_ctrl_M,
    output reg         jal_M, // Add jal_M output
    
    output reg  [31:0] alu_out_M,
    output reg  [31:0] wd_dm_M,
    output reg  [4:0]  write_reg_M,
    output reg  [31:0] pc_plus4_M,
    output reg  [63:0] mult_product_M
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_dm_M        <= 1'b0;
            dm2reg_M       <= 1'b0;
            we_reg_M       <= 1'b0;
            hilo_wd_M      <= 1'b0;
            hilo_mux_ctrl_M <= 2'b0;
            jal_M          <= 1'b0;
            
            alu_out_M      <= 32'b0;
            wd_dm_M        <= 32'b0;
            write_reg_M    <= 5'b0;
            pc_plus4_M     <= 32'b0;
            mult_product_M <= 64'b0;
        end
        else begin
            we_dm_M        <= we_dm_E;
            dm2reg_M       <= dm2reg_E;
            we_reg_M       <= we_reg_E;
            hilo_wd_M      <= hilo_wd_E;
            hilo_mux_ctrl_M <= hilo_mux_ctrl_E;
            jal_M          <= jal_E;
            
            alu_out_M      <= alu_out_E;
            wd_dm_M        <= wd_dm_E;
            write_reg_M    <= write_reg_E;
            pc_plus4_M     <= pc_plus4_E;
            mult_product_M <= mult_product_E;
        end
    end

endmodule
