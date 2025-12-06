module datapath (
    input  wire        clk,
    input  wire        rst,
    input  wire        branch,
    input  wire        jump,
    input  wire        jal,
    input  wire        jump_reg,
    input wire         hilo_wd, 
    input wire [1:0] hilo_mux_ctrl,
    input  wire        reg_dst,
    input  wire        we_reg,
    input  wire        alu_src,
    input  wire        dm2reg,
    input  wire [3:0]  alu_ctrl,
    input  wire [4:0]  ra3,
    input  wire [31:0] instr,
    input  wire [31:0] rd_dm,
    output wire [31:0] pc_current,
    output wire [31:0] alu_out,
    output wire [31:0] wd_dm,
    output wire [31:0] rd3
);
    wire [4:0]  rf_wa_base;
    wire [4:0]  rf_wa;
    wire        pc_src;
    wire [31:0] pc_plus4;
    wire [31:0] pc_pre;
    wire [31:0] pc_next;
    wire [31:0] sext_imm;
    wire [31:0] ba;
    wire [31:0] bta;
    wire [31:0] jta;
    wire [31:0] alu_pa;
    wire [31:0] alu_pb;
    wire [31:0] wd_rf;
    wire        zero;
    wire [31:0] pc_plus4_internal;
    
    // Multiplier signals
    wire [63:0] mult_product;
    wire        multu_we;
    wire [31:0] hi_out;
    wire [31:0] lo_out;
    
    assign pc_src = branch & zero;
    assign ba = {sext_imm[29:0], 2'b00};
    assign jta = {pc_plus4_internal[31:28], instr[25:0], 2'b00};
    
    // --- PC Logic — //
    dreg pc_reg (.clk(clk), .rst(rst), .d(pc_next), .q(pc_current));
    adder pc_plus_4 (.a(pc_current), .b(32'd4), .y(pc_plus4_internal));
    assign pc_plus4 = pc_plus4_internal;
    adder pc_plus_br (.a(pc_plus4_internal), .b(ba), .y(bta));
    mux2 #(32) pc_src_mux (.sel(pc_src), .a(pc_plus4_internal), .b(bta), .y(pc_pre));
    mux2 #(32) pc_jr_mux (.sel(jump_reg), .a(pc_pre), .b(alu_pa), .y(pc_after_jr_or_pre));
    mux2 #(32) pc_jmp_mux (.sel(jump), .a(pc_after_jr_or_pre), .b(jta), .y(pc_next));
    
    wire [31:0] pc_after_jr_or_pre;
    
    // --- RF Logic — //
    mux2 #(5) rf_wa_mux (.sel(reg_dst), .a(instr[20:16]), .b(instr[15:11]), .y(rf_wa_base));
    assign rf_wa = (jal) ? 5'd31 : rf_wa_base;
    
    regfile rf (
        .clk(clk),
        .we(we_reg),
        .ra1(instr[25:21]),
        .ra2(instr[20:16]),
        .ra3(ra3),
        .wa(rf_wa),
        .wd(wd_rf),
        .rd1(alu_pa),
        .rd2(wd_dm),
        .rd3(rd3),
        .rst(rst)
    );
    
    signext se (.a(instr[15:0]), .y(sext_imm));
    
    // Multiplier Module 
    multiplier mult (
        .a(alu_pa),
        .b(wd_dm),
        .product(mult_product)
    );
    
    // Write enable for HiLo: active when MULTU instruction (alu_ctrl == 4'b0011)
    assign multu_we = hilo_wd;
    
    // HiLo Register Module 
         hilo_reg hilo (
        .clk(clk),
        .rst(rst),
        .we(multu_we),
        .product(mult_product),
        .hi(hi_out),
        .lo(lo_out)   );
    
    //--- ALU Logic --- //
    wire [4:0] shamt;
    assign shamt = instr[10:6];
    
    mux2 #(32) alu_pb_mux (.sel(alu_src), .a(wd_dm), .b(sext_imm), .y(alu_pb));
    
    wire [31:0] alu_y;
    alu alu0 (
        .op(alu_ctrl),
        .a(alu_pa),
        .b(alu_pb),
        .shamt(shamt),
        .zero(zero),
        .y(alu_y)
    );
    
    // 3-to-1 MUX for ALU output / MFHI / MFLO : 
    reg [31:0] alu_out_sel;
    always @(*) begin
        case (hilo_mux_ctrl)
            2'b01: alu_out_sel = hi_out;  // MFHI
            2'b10: alu_out_sel = lo_out;  // MFLO
            default: alu_out_sel = alu_y;   // ALU result
        endcase
    end
    assign alu_out = alu_out_sel;
    
    //  Writeback Selection
    wire [31:0] alu_or_mem;
    mux2 #(32) rf_wd_mem_mux (.sel(dm2reg), .a(alu_out), .b(rd_dm), .y(alu_or_mem));
    assign wd_rf = (jal) ? pc_plus4_internal : alu_or_mem;
    
endmodule 
