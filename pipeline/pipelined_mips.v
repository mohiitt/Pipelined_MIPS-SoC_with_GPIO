// ============================================================================
// Pipelined MIPS Top-Level Module
// 5-Stage Pipeline: IF -> ID -> EX -> MEM -> WB
// Includes hazard detection, forwarding, and control hazard handling
// ============================================================================

module pipelined_mips (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3,            // Test read address
    input  wire [31:0] instr,          // Instruction from IMEM
    input  wire [31:0] rd_dm,          // Data from DMEM
    output wire        we_dm,          // DMEM write enable
    output wire [31:0] pc_current,     // Current PC (for IMEM)
    output wire [31:0] alu_out,        // Address for DMEM
    output wire [31:0] wd_dm,          // Write data for DMEM
    output wire        mem_read_dm,    // DMEM read enable
    output wire [31:0] rd3             // Test read output
);

    // Instantiate pipelined datapath
    pipelined_datapath dp (
        .clk(clk),
        .rst(rst),
        .instr_F(instr),
        .rd_dm(rd_dm),
        .ra3(ra3),
        .rd3(rd3),
        .pc_F(pc_current),
        .alu_out_M(alu_out),
        .wd_dm_M(wd_dm),
        .we_dm_M(we_dm),
        .mem_read_M(mem_read_dm)
    );

endmodule
