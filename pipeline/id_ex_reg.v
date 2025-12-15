

module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,

    input  wire        reg_dst_D,
    input  wire        alu_src_D,
    input  wire [3:0]  alu_ctrl_D,
    input  wire        we_dm_D,
    input  wire        dm2reg_D,
    input  wire        we_reg_D,
    input  wire        hilo_wd_D,
    input  wire [1:0]  hilo_mux_ctrl_D,
    input  wire        jal_D,
    input  wire        valid_D,

    input  wire [31:0] rd1_D,
    input  wire [31:0] rd2_D,
    input  wire [4:0]  rs_D,
    input  wire [4:0]  rt_D,
    input  wire [4:0]  rd_D,
    input  wire [31:0] sext_imm_D,
    input  wire [4:0]  shamt_D,
    input  wire [31:0] pc_plus4_D,

    output reg         reg_dst_E,
    output reg         alu_src_E,
    output reg  [3:0]  alu_ctrl_E,
    output reg         we_dm_E,
    output reg         dm2reg_E,
    output reg         we_reg_E,
    output reg         hilo_wd_E,
    output reg  [1:0]  hilo_mux_ctrl_E,
    output reg         jal_E,
    output reg         valid_E,

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

            reg_dst_E      <= 1'b0;
            alu_src_E      <= 1'b0;
            alu_ctrl_E     <= 4'b0;
            we_dm_E        <= 1'b0;
            dm2reg_E       <= 1'b0;
            we_reg_E       <= 1'b0;
            hilo_wd_E      <= 1'b0;
            hilo_mux_ctrl_E <= 2'b0;
            jal_E          <= 1'b0;
            valid_E        <= 1'b0;

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

            reg_dst_E      <= 1'b0;
            alu_src_E      <= 1'b0;
            alu_ctrl_E     <= 4'b0;
            we_dm_E        <= 1'b0;
            dm2reg_E       <= 1'b0;
            we_reg_E       <= 1'b0;
            hilo_wd_E      <= 1'b0;
            hilo_mux_ctrl_E <= 2'b0;
            jal_E          <= 1'b0;
            valid_E        <= 1'b0;

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

            reg_dst_E      <= reg_dst_D;
            alu_src_E      <= alu_src_D;
            alu_ctrl_E     <= alu_ctrl_D;
            we_dm_E        <= we_dm_D;
            dm2reg_E       <= dm2reg_D;
            we_reg_E       <= we_reg_D;
            hilo_wd_E      <= hilo_wd_D;
            hilo_mux_ctrl_E <= hilo_mux_ctrl_D;
            jal_E          <= jal_D;
            valid_E        <= valid_D;

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