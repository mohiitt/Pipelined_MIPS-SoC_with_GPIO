// ============================================================================
// Pipelined Datapath for 5-Stage MIPS CPU
// Stages: IF -> ID -> EX -> MEM -> WB
// Includes forwarding, hazard detection, and pipeline registers
// ============================================================================

module pipelined_datapath (
    input  wire        clk,
    input  wire        rst,
    
    // External memory interfaces
    input  wire [31:0] instr_F,        // Instruction from IMEM
    input  wire [31:0] rd_dm,          // Data from DMEM
    
    // External test interface
    input  wire [4:0]  ra3,
    output wire [31:0] rd3,
    
    // Outputs
    output wire [31:0] pc_F,           // PC for instruction fetch
    output wire [31:0] alu_out_M,      // Address for data memory
    output wire [31:0] wd_dm_M,        // Write data for memory
    output wire        we_dm_M         // Memory write enable
);

    // ========================================================================
    // IF Stage Signals
    // ========================================================================
    wire [31:0] pc_next_F;
    wire [31:0] pc_plus4_F;
    wire        stall_F;
    
    // ========================================================================
    // IF/ID Pipeline Register Signals
    // ========================================================================
    wire [31:0] instr_D;
    wire [31:0] pc_plus4_D;
    wire        stall_D;
    wire        flush_D;
    
    // ========================================================================
    // ID Stage Signals
    // ========================================================================
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
    
    // ========================================================================
    // ID/EX Pipeline Register Signals
    // ========================================================================
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
    
    // ========================================================================
    // EX Stage Signals
    // ========================================================================
    wire [1:0]  forward_A;
    wire [1:0]  forward_B;
    wire [31:0] alu_pa_fwd;
    wire [31:0] alu_pb_fwd;
    wire [31:0] alu_pb_E;
    wire [31:0] alu_out_E;
    wire [4:0]  write_reg_E;
    wire [63:0] mult_product_E;
    wire        zero_E;
    
    // ========================================================================
    // EX/MEM Pipeline Register Signals
    // ========================================================================
    wire        dm2reg_M;
    wire        we_reg_M;
    wire        hilo_wd_M;
    wire [1:0]  hilo_mux_ctrl_M;
    wire [4:0]  write_reg_M;
    wire [31:0] pc_plus4_M;
    wire [63:0] mult_product_M;
    
    // ========================================================================
    // MEM Stage Signals
    // ========================================================================
    wire [31:0] hi_out_M;
    wire [31:0] lo_out_M;
    
    // ========================================================================
    // MEM/WB Pipeline Register Signals
    // ========================================================================
    wire        dm2reg_W;
    wire        we_reg_W;
    wire [1:0]  hilo_mux_ctrl_W;
    wire [31:0] alu_out_W;
    wire [31:0] rd_dm_W;
    wire [4:0]  write_reg_W;
    wire [31:0] pc_plus4_W;
    wire [31:0] hi_out_W;
    wire [31:0] lo_out_W;
    
    // ========================================================================
    // WB Stage Signals
    // ========================================================================
    wire [31:0] result_W;
    
    // ========================================================================
    // JAL support
    // ========================================================================
    wire        jal_E;
    wire        jal_M;
    wire        jal_W;
    wire [4:0]  final_write_reg_W;
    wire [31:0] final_wd_W;
    
    // ========================================================================
    // IF STAGE
    // ========================================================================
    
    // PC register with enable (for stalls)
    dreg #(32) pc_reg (
        .clk(clk),
        .rst(rst),
        .en(~stall_F),
        .d(pc_next_F),
        .q(pc_F)
    );
    
    // PC + 4
    adder pc_adder (
        .a(pc_F),
        .b(32'd4),
        .y(pc_plus4_F)
    );
    
    // PC source selection (from ID stage)
    assign pc_next_F = (jump_D) ? jta_D :
                       (pc_src_D) ? bta_D :
                       (jump_reg_D) ? rd1_D :  // JR uses rs value
                       pc_plus4_F;
    
    // Flush IF/ID on control transfers
    assign flush_D = (jump_D | jal_D | pc_src_D | jump_reg_D);
    
    // ========================================================================
    // IF/ID Pipeline Register
    // ========================================================================
    if_id_reg if_id (
        .clk(clk),
        .rst(rst),
        .enable(~stall_D),
        .flush(flush_D),
        .instr_F(instr_F),
        .pc_plus4_F(pc_plus4_F),
        .instr_D(instr_D),
        .pc_plus4_D(pc_plus4_D)
    );
    
    // ========================================================================
    // ID STAGE
    // ========================================================================
    
    // Instruction decode
    assign opcode_D = instr_D[31:26];
    assign funct_D  = instr_D[5:0];
    assign rs_D     = instr_D[25:21];
    assign rt_D     = instr_D[20:16];
    assign rd_D     = instr_D[15:11];
    assign shamt_D  = instr_D[10:6];
    assign imm_D    = instr_D[15:0];
    
    // Control unit
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
        .hilo_mux_ctrl(hilo_mux_ctrl_D)
    );
    
    // Register file (writes in WB stage)
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
    
    // Sign extend
    signext se (
        .a(imm_D),
        .y(sext_imm_D)
    );
    
    // Branch target address
    wire [31:0] ba_D;
    assign ba_D = {sext_imm_D[29:0], 2'b00};
    adder branch_adder (
        .a(pc_plus4_D),
        .b(ba_D),
        .y(bta_D)
    );
    
    // Jump target address
    assign jta_D = {pc_plus4_D[31:28], instr_D[25:0], 2'b00};
    
    // Branch comparator (early branch resolution in ID)
    assign zero_D = (rd1_D == rd2_D);
    assign pc_src_D = branch_D & zero_D;
    
    // ========================================================================
    // Hazard Detection Unit
    // ========================================================================
    hazard_unit hdu (
        .rs_D(rs_D),
        .rt_D(rt_D),
        .branch_D(branch_D),
        .jump_reg_D(jump_reg_D),
        .rt_E(rt_E),
        .write_reg_E(write_reg_E),
        .we_reg_E(we_reg_E),
        .dm2reg_E(dm2reg_E),
        .write_reg_M(write_reg_M),
        .we_reg_M(we_reg_M),
        .stall_F(stall_F),
        .stall_D(stall_D),
        .flush_E(flush_E)
    );
    
    // ========================================================================
    // ID/EX Pipeline Register
    // ========================================================================
    id_ex_reg id_ex (
        .clk(clk),
        .rst(rst),
        .flush(flush_E | flush_D),
        .reg_dst_D(reg_dst_D),
        .alu_src_D(alu_src_D),
        .alu_ctrl_D(alu_ctrl_D),
        .we_dm_D(we_dm_D),
        .dm2reg_D(dm2reg_D),
        .we_reg_D(we_reg_D),
        .hilo_wd_D(hilo_wd_D),
        .hilo_mux_ctrl_D(hilo_mux_ctrl_D),
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
        .rd1_E(rd1_E),
        .rd2_E(rd2_E),
        .rs_E(rs_E),
        .rt_E(rt_E),
        .rd_E(rd_E),
        .sext_imm_E(sext_imm_E),
        .shamt_E(shamt_E),
        .pc_plus4_E(pc_plus4_E)
    );
    
    // ========================================================================
    // EX STAGE
    // ========================================================================
    
    // Forwarding Unit
    forwarding_unit fwd (
        .rs_E(rs_E),
        .rt_E(rt_E),
        .write_reg_M(write_reg_M),
        .we_reg_M(we_reg_M),
        .write_reg_W(write_reg_W),
        .we_reg_W(we_reg_W),
        .forward_A(forward_A),
        .forward_B(forward_B)
    );
    
    // Forward mux for ALU input A
    assign alu_pa_fwd = (forward_A == 2'b10) ? alu_out_M :
                        (forward_A == 2'b01) ? result_W :
                        rd1_E;
    
    // Forward mux for ALU input B (before alu_src mux)
    assign alu_pb_fwd = (forward_B == 2'b10) ? alu_out_M :
                        (forward_B == 2'b01) ? result_W :
                        rd2_E;
    
    // ALU source mux
    mux2 #(32) alu_src_mux (
        .sel(alu_src_E),
        .a(alu_pb_fwd),
        .b(sext_imm_E),
        .y(alu_pb_E)
    );
    
    // ALU
    alu alu0 (
        .op(alu_ctrl_E),
        .a(alu_pa_fwd),
        .b(alu_pb_E),
        .shamt(shamt_E),
        .zero(zero_E),
        .y(alu_out_E)
    );
    
    // Multiplier
    multiplier mult (
        .a(alu_pa_fwd),
        .b(alu_pb_fwd),
        .product(mult_product_E)
    );
    
    // Write register selection
    mux2 #(5) write_reg_mux (
        .sel(reg_dst_E),
        .a(rt_E),
        .b(rd_E),
        .y(write_reg_E)
    );
    
    // ========================================================================
    // EX/MEM Pipeline Register
    // ========================================================================
    ex_mem_reg ex_mem (
        .clk(clk),
        .rst(rst),
        .we_dm_E(we_dm_E),
        .dm2reg_E(dm2reg_E),
        .we_reg_E(we_reg_E),
        .hilo_wd_E(hilo_wd_E),
        .hilo_mux_ctrl_E(hilo_mux_ctrl_E),
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
        .alu_out_M(alu_out_M),
        .wd_dm_M(wd_dm_M),
        .write_reg_M(write_reg_M),
        .pc_plus4_M(pc_plus4_M),
        .mult_product_M(mult_product_M)
    );
    
    // ========================================================================
    // MEM STAGE
    // ========================================================================
    
    // HILO Register
    hilo_reg hilo (
        .clk(clk),
        .rst(rst),
        .we(hilo_wd_M),
        .product(mult_product_M),
        .hi(hi_out_M),
        .lo(lo_out_M)
    );
    
    // ========================================================================
    // MEM/WB Pipeline Register
    // ========================================================================
    mem_wb_reg mem_wb (
        .clk(clk),
        .rst(rst),
        .dm2reg_M(dm2reg_M),
        .we_reg_M(we_reg_M),
        .hilo_mux_ctrl_M(hilo_mux_ctrl_M),
        .alu_out_M(alu_out_M),
        .rd_dm_M(rd_dm),
        .write_reg_M(write_reg_M),
        .pc_plus4_M(pc_plus4_M),
        .hi_out_M(hi_out_M),
        .lo_out_M(lo_out_M),
        .dm2reg_W(dm2reg_W),
        .we_reg_W(we_reg_W),
        .hilo_mux_ctrl_W(hilo_mux_ctrl_W),
        .alu_out_W(alu_out_W),
        .rd_dm_W(rd_dm_W),
        .write_reg_W(write_reg_W),
        .pc_plus4_W(pc_plus4_W),
        .hi_out_W(hi_out_W),
        .lo_out_W(lo_out_W)
    );
    
    // ========================================================================
    // WB STAGE
    // ========================================================================
    
    // HILO output selection
    reg [31:0] alu_or_hilo_W;
    always @(*) begin
        case (hilo_mux_ctrl_W)
            2'b01:   alu_or_hilo_W = hi_out_W;   // MFHI
            2'b10:   alu_or_hilo_W = lo_out_W;   // MFLO
            default: alu_or_hilo_W = alu_out_W;  // Normal ALU result
        endcase
    end
    
    // Memory to register mux
    mux2 #(32) mem_to_reg_mux (
        .sel(dm2reg_W),
        .a(alu_or_hilo_W),
        .b(rd_dm_W),
        .y(result_W)
    );
    
    // JAL support - detect JAL in pipeline
    // JAL writes $ra (reg 31) instead of normal destination
    // JAL writes PC+4 instead of ALU/memory result
    assign jal_W = (write_reg_W == 5'd31) && we_reg_W;  // Simplified JAL detection
    assign final_write_reg_W = write_reg_W;  // Already set to 31 by reg_dst mux in ID
    assign final_wd_W = jal_W ? pc_plus4_W : result_W;

endmodule
