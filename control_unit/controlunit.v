module controlunit (
    input  wire [5:0]  opcode,
    input  wire [5:0]  funct,
    output wire        branch,
    output wire        jump,
    output wire        jal,
    output wire        reg_dst,
    output wire        we_reg,
    output wire        alu_src,
    output wire        we_dm,
    output wire        dm2reg,
    output wire [3:0]  alu_ctrl,
    output wire        jump_reg,
    output wire        hilo_wd, 
    output wire [1:0] hilo_mux_ctrl,
    output wire       valid_inst
);

    wire [1:0] alu_op;
    wire jr_signal;
    wire hilo_wd_internal; 
    wire [1:0] hilo_mux_internal;

    maindec md (
        .opcode         (opcode),
        .branch         (branch),
        .jump           (jump),
        .jal            (jal),
        .reg_dst        (reg_dst),
        .we_reg         (we_reg),
        .alu_src        (alu_src),
        .we_dm          (we_dm),
        .dm2reg         (dm2reg),
        .alu_op         (alu_op),
        .valid_inst     (valid_inst)
    );

    auxdec ad (
        .alu_op         (alu_op),
        .funct          (funct),
        .alu_ctrl       (alu_ctrl),
        .jr                 (jr_signal), 
        .hilo_wd      (hilo_wd_internal), 
        .hilo_mux_ctrl(hilo_mux_internal)
    );

    assign jump_reg = jr_signal;
    assign hilo_wd = hilo_wd_internal; 
    assign hilo_mux_ctrl = hilo_mux_internal;
endmodule
