// ============================================================================
// Pipelined MIPS Top-Level with Instruction and Data Memory
// Complete system including IMEM, DMEM, and pipelined CPU
// ============================================================================

module pipelined_mips_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3
);

    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] data_addr;
    wire [31:0] write_data;
    wire [31:0] read_data;
    wire        mem_write;
    wire [31:0] rd3;

    // Instruction Memory
    imem instruction_memory (
        .a(pc[7:2]),           // Word-addressed
        .rd(instr)
    );

    // Pipelined MIPS CPU
    pipelined_mips cpu (
        .clk(clk),
        .rst(rst),
        .ra3(ra3),
        .instr(instr),
        .rd_dm(read_data),
        .we_dm(mem_write),
        .pc_current(pc),
        .alu_out(data_addr),
        .wd_dm(write_data),
        .rd3(rd3)
    );

    // Data Memory
    dmem data_memory (
        .clk(clk),
        .we(mem_write),
        .a(data_addr[7:2]),    // Word-addressed
        .wd(write_data),
        .rd(read_data),
        .rst(rst)
    );

endmodule
