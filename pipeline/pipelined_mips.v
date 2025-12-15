

module pipelined_mips (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3,
    input  wire [31:0] instr,
    input  wire [31:0] rd_dm,
    output wire        we_dm,
    output wire [31:0] pc_current,
    output wire [31:0] alu_out,
    output wire [31:0] wd_dm,
    output wire        mem_read_dm,
    output wire [31:0] rd3
);

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