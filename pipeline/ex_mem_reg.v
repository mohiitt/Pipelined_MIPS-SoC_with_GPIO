

module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,

    input  wire        we_dm_E,
    input  wire        dm2reg_E,
    input  wire        we_reg_E,
    input  wire        hilo_wd_E,
    input  wire [1:0]  hilo_mux_ctrl_E,
    input  wire        jal_E,
    input  wire        valid_E,

    input  wire [31:0] alu_out_E,
    input  wire [31:0] wd_dm_E,
    input  wire [4:0]  write_reg_E,
    input  wire [31:0] pc_plus4_E,
    input  wire [63:0] mult_product_E,

    output reg         we_dm_M,
    output reg         dm2reg_M,
    output reg         we_reg_M,
    output reg         hilo_wd_M,
    output reg  [1:0]  hilo_mux_ctrl_M,
    output reg         jal_M,
    output reg         valid_M,

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
            valid_M        <= 1'b0;

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
            valid_M        <= valid_E;

            alu_out_M      <= alu_out_E;
            wd_dm_M        <= wd_dm_E;
            write_reg_M    <= write_reg_E;
            pc_plus4_M     <= pc_plus4_E;
            mult_product_M <= mult_product_E;
        end
    end

endmodule