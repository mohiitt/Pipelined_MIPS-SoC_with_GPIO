

module pipelined_datapath (
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] instr_F,
    input  wire [31:0] rd_dm,

    input  wire [4:0]  ra3,
    output wire [31:0] rd3,

    output wire [31:0] pc_F,
    output wire [31:0] alu_out_M,
    output wire [31:0] wd_dm_M,
    output wire        we_dm_M,
    output wire        mem_read_M
);

    wire [31:0] pc_next_F;
    wire [31:0] pc_plus4_F;
    wire        stall_F;

    wire [31:0] instr_D;
    wire [31:0] pc_plus4_D;
    wire        stall_D;
    wire        flush_D;
    wire        valid_D;

    wire [5:0]  opcode_D;
    wire [5:0]  funct_D;
    wire [4:0]  rs_D;
    wire [4:0]  rt_D;
    wire [4:0]  rd_D;
    wire [4:0]  shamt_D;
    wire [15:0] imm_D;

    wire        branch_D;
    wire        jump_D;
    wire        jal_D;
    wire        jump_reg_D;
    wire        reg_dst_D;
    wire        we_reg_D;
    wire        alu_src_D;
    wire        we_dm_D;
    wire        valid_inst_D;
    wire        dm2reg_D;
    wire [3:0]  alu_ctrl_D;
    wire        hilo_wd_D;
    wire [1:0]  hilo_mux_ctrl_D;

    wire [31:0] rd1_D;
    wire [31:0] rd2_D;
    wire [31:0] sext_imm_D;
    wire [31:0] bta_D;
    wire [31:0] jta_D;
    wire        zero_D;
    wire        pc_src_D;

    wire        reg_dst_E;
    wire        alu_src_E;
    wire [3:0]  alu_ctrl_E;
    wire        we_dm_E;
    wire        dm2reg_E;
    wire        we_reg_E;
    wire        hilo_wd_E;
    wire [1:0]  hilo_mux_ctrl_E;

    wire [31:0] rd1_E;
    wire [31:0] rd2_E;
    wire [4:0]  rs_E;
    wire [4:0]  rt_E;
    wire [4:0]  rd_E;
    wire [31:0] sext_imm_E;
    wire [4:0]  shamt_E;
    wire [31:0] pc_plus4_E;
    wire        flush_E;
    wire        valid_E;

    wire [1:0]  forward_A;
    wire [1:0]  forward_B;
    wire [31:0] alu_pa_fwd;
    wire [31:0] alu_pb_fwd;
    wire [31:0] alu_pb_E;
    wire [31:0] alu_out_E;
    wire [4:0]  write_reg_E;
    wire [63:0] mult_product_E;
    wire        zero_E;

    wire        dm2reg_M;
    wire        we_reg_M;
    wire        hilo_wd_M;
    wire [1:0]  hilo_mux_ctrl_M;
    wire [4:0]  write_reg_M;
    wire [31:0] pc_plus4_M;
    wire [63:0] mult_product_M;
    wire        valid_M;

    wire [31:0] hi_out_M;
    wire [31:0] lo_out_M;

    wire        dm2reg_W;
    wire        we_reg_W;
    wire [1:0]  hilo_mux_ctrl_W;
    wire [31:0] alu_out_W;
    wire [31:0] rd_dm_W;
    wire [4:0]  write_reg_W;
    wire [31:0] pc_plus4_W;
    wire [31:0] hi_out_W;
    wire [31:0] lo_out_W;

    wire [31:0] result_W;
    wire        valid_W;

    wire        jal_E;
    wire        jal_M;
    wire        jal_W;
    wire [4:0]  final_write_reg_W;
    wire [31:0] final_wd_W;

    dreg #(32) pc_reg (
        .clk(clk),
        .rst(rst),
        .en(~stall_F),
        .d(pc_next_F),
        .q(pc_F)
    );

    adder pc_adder (
        .a(pc_F),
        .b(32'd4),
        .y(pc_plus4_F)
    );

    assign flush_D = flush_D_haz;

    if_id_reg if_id (
        .clk(clk),
        .rst(rst),
        .enable(~stall_D),
        .flush(flush_D),
        .instr_F(instr_F),
        .pc_plus4_F(pc_plus4_F),
        .instr_D(instr_D),
        .pc_plus4_D(pc_plus4_D),
        .valid_D(valid_D)
    );

    assign opcode_D = instr_D[31:26];
    assign funct_D  = instr_D[5:0];
    assign rs_D     = instr_D[25:21];
    assign rt_D     = instr_D[20:16];
    assign rd_D     = instr_D[15:11];
    assign shamt_D  = instr_D[10:6];
    assign imm_D    = instr_D[15:0];

    controlunit cu (
        .opcode(opcode_D),
        .funct(funct_D),
        .branch(branch_D),
        .jump(jump_D),
        .jal(jal_D),
        .reg_dst(reg_dst_D),
        .we_reg(we_reg_D),
        .alu_src(alu_src_D),
        .we_dm(we_dm_D),
        .dm2reg(dm2reg_D),
        .alu_ctrl(alu_ctrl_D),
        .jump_reg(jump_reg_D),
        .hilo_wd(hilo_wd_D),
        .hilo_mux_ctrl(hilo_mux_ctrl_D),
        .valid_inst(valid_inst_D)
    );

    wire jump_combo_D;
    wire jump_reg_combo_D;

    regfile rf (
        .clk(clk),
        .we(we_reg_W),
        .ra1(rs_D),
        .ra2(rt_D),
        .ra3(ra3),
        .wa(final_write_reg_W),
        .wd(final_wd_W),
        .rd1(rd1_D),
        .rd2(rd2_D),
        .rd3(rd3),
        .rst(rst)
    );

    signext se (
        .a(imm_D),
        .y(sext_imm_D)
    );

    wire [31:0] ba_D;
    assign ba_D = {sext_imm_D[29:0], 2'b00};
    adder branch_adder (
        .a(pc_plus4_D),
        .b(ba_D),
        .y(bta_D)
    );

    assign jta_D = {pc_plus4_D[31:28], instr_D[25:0], 2'b00};

    reg [31:0] cmp1_D;
    reg [31:0] cmp2_D;

    always @(*) begin

        if ((rs_D != 0) && (rs_D == write_reg_E) && we_reg_E && !dm2reg_E)
            cmp1_D = alu_out_E;

        else if ((rs_D != 0) && (rs_D == write_reg_M) && we_reg_M)
            cmp1_D = alu_out_M;
        else
            cmp1_D = rd1_D;

        if ((rt_D != 0) && (rt_D == write_reg_E) && we_reg_E && !dm2reg_E)
            cmp2_D = alu_out_E;

        else if ((rt_D != 0) && (rt_D == write_reg_M) && we_reg_M)
            cmp2_D = alu_out_M;
        else
            cmp2_D = rd2_D;
    end

    assign zero_D = (cmp1_D == cmp2_D);
    assign pc_src_D = branch_D & zero_D;

    assign pc_next_F = (jump_D) ? jta_D :
                       (pc_src_D) ? bta_D :
                       (jump_reg_D) ? cmp1_D :
                       pc_plus4_F;

    wire [1:0] forward_A_haz;
    wire [1:0] forward_B_haz;
    wire       flush_D_haz;

    hazard_unit hdu (

        .RsD(rs_D),
        .RtD(rt_D),
        .BranchD(pc_src_D),
        .JumpD(jump_D),
        .JumpRegD(jump_reg_D),
        .OpcodeD(opcode_D),
        .FunctD(funct_D),
        .clk(clk),
        .rst(rst),

        .RsE(rs_E),
        .RtE(rt_E),
        .wa_reg_E(write_reg_E),
        .we_reg_E(we_reg_E),
        .dm2reg_E(dm2reg_E),

        .wa_reg_M(write_reg_M),
        .we_reg_M(we_reg_M),
        .dm2reg_M(dm2reg_M),

        .wa_reg_W(write_reg_W),
        .we_reg_W(we_reg_W),

        .StallF(stall_F),
        .StallD(stall_D),
        .FlushE(flush_E),
        .FlushD(flush_D_haz),
        .ForwardAE(forward_A_haz),
        .ForwardBE(forward_B_haz)
    );

    assign forward_A = forward_A_haz;
    assign forward_B = forward_B_haz;

    id_ex_reg id_ex (
        .clk(clk),
        .rst(rst),
        .flush(flush_E),
        .valid_D(valid_D & valid_inst_D),
        .reg_dst_D(reg_dst_D),
        .alu_src_D(alu_src_D),
        .alu_ctrl_D(alu_ctrl_D),
        .we_dm_D(we_dm_D),
        .dm2reg_D(dm2reg_D),
        .we_reg_D(we_reg_D),
        .hilo_wd_D(hilo_wd_D),
        .hilo_mux_ctrl_D(hilo_mux_ctrl_D),
        .jal_D(jal_D),
        .rd1_D(rd1_D),
        .rd2_D(rd2_D),
        .rs_D(rs_D),
        .rt_D(rt_D),
        .rd_D(rd_D),
        .sext_imm_D(sext_imm_D),
        .shamt_D(shamt_D),
        .pc_plus4_D(pc_plus4_D),
        .reg_dst_E(reg_dst_E),
        .alu_src_E(alu_src_E),
        .alu_ctrl_E(alu_ctrl_E),
        .we_dm_E(we_dm_E),
        .dm2reg_E(dm2reg_E),
        .we_reg_E(we_reg_E),
        .hilo_wd_E(hilo_wd_E),
        .hilo_mux_ctrl_E(hilo_mux_ctrl_E),
        .jal_E(jal_E),
        .valid_E(valid_E),
        .rd1_E(rd1_E),
        .rd2_E(rd2_E),
        .rs_E(rs_E),
        .rt_E(rt_E),
        .rd_E(rd_E),
        .sext_imm_E(sext_imm_E),
        .shamt_E(shamt_E),
        .pc_plus4_E(pc_plus4_E)
    );

    assign alu_pa_fwd = (forward_A == 2'b10) ? alu_out_M :
                        (forward_A == 2'b01) ? result_W :
                        rd1_E;

    assign alu_pb_fwd = (forward_B == 2'b10) ? alu_out_M :
                        (forward_B == 2'b01) ? result_W :
                        rd2_E;

    mux2 #(32) alu_src_mux (
        .sel(alu_src_E),
        .a(alu_pb_fwd),
        .b(sext_imm_E),
        .y(alu_pb_E)
    );

    alu alu0 (
        .op(alu_ctrl_E),
        .a(alu_pa_fwd),
        .b(alu_pb_E),
        .shamt(shamt_E),
        .zero(zero_E),
        .y(alu_out_E)
    );

    multiplier mult (
        .a(alu_pa_fwd),
        .b(alu_pb_fwd),
        .product(mult_product_E)
    );

    wire [4:0] write_reg_tmp_E;
    mux2 #(5) write_reg_mux (
        .sel(reg_dst_E),
        .a(rt_E),
        .b(rd_E),
        .y(write_reg_tmp_E)
    );
    assign write_reg_E = (jal_E) ? 5'd31 : write_reg_tmp_E;

    ex_mem_reg ex_mem (
        .clk(clk),
        .rst(rst),
        .we_dm_E(we_dm_E),
        .dm2reg_E(dm2reg_E),
        .we_reg_E(we_reg_E),
        .hilo_wd_E(hilo_wd_E),
        .hilo_mux_ctrl_E(hilo_mux_ctrl_E),
        .jal_E(jal_E),
        .valid_E(valid_E),
        .alu_out_E(alu_out_E),
        .wd_dm_E(alu_pb_fwd),
        .write_reg_E(write_reg_E),
        .pc_plus4_E(pc_plus4_E),
        .mult_product_E(mult_product_E),

        .we_dm_M(we_dm_M),
        .dm2reg_M(dm2reg_M),
        .we_reg_M(we_reg_M),
        .hilo_wd_M(hilo_wd_M),
        .hilo_mux_ctrl_M(hilo_mux_ctrl_M),
        .jal_M(jal_M),
        .valid_M(valid_M),
        .alu_out_M(alu_out_M),
        .wd_dm_M(wd_dm_M),
        .write_reg_M(write_reg_M),
        .pc_plus4_M(pc_plus4_M),
        .mult_product_M(mult_product_M)
    );

    hilo_reg hilo (
        .clk(clk),
        .rst(rst),
        .we(hilo_wd_M),
        .product(mult_product_M),
        .hi(hi_out_M),
        .lo(lo_out_M)
    );

    mem_wb_reg mem_wb (
        .clk(clk),
        .rst(rst),
        .dm2reg_M(dm2reg_M),
        .we_reg_M(we_reg_M),
        .hilo_mux_ctrl_M(hilo_mux_ctrl_M),
        .jal_M(jal_M),
        .valid_M(valid_M),
        .alu_out_M(alu_out_M),
        .rd_dm_M(rd_dm),
        .write_reg_M(write_reg_M),
        .pc_plus4_M(pc_plus4_M),
        .hi_out_M(hi_out_M),
        .lo_out_M(lo_out_M),

        .dm2reg_W(dm2reg_W),
        .we_reg_W(we_reg_W),
        .hilo_mux_ctrl_W(hilo_mux_ctrl_W),
        .jal_W(jal_W),
        .valid_W(valid_W),
        .alu_out_W(alu_out_W),
        .rd_dm_W(rd_dm_W),
        .write_reg_W(write_reg_W),
        .pc_plus4_W(pc_plus4_W),
        .hi_out_W(hi_out_W),
        .lo_out_W(lo_out_W)
    );

    reg [31:0] alu_or_hilo_W;
    always @(*) begin
        case (hilo_mux_ctrl_W)
            2'b01:   alu_or_hilo_W = hi_out_W;
            2'b10:   alu_or_hilo_W = lo_out_W;
            default: alu_or_hilo_W = alu_out_W;
        endcase
    end

    mux2 #(32) mem_to_reg_mux (
        .sel(dm2reg_W),
        .a(alu_or_hilo_W),
        .b(rd_dm_W),
        .y(result_W)
    );

    assign final_write_reg_W = write_reg_W;
    assign final_write_reg_W = write_reg_W;

    assign final_wd_W = jal_W ? pc_plus4_W : result_W;

    assign mem_read_M = dm2reg_M;

endmodule