

module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,

    input  wire        dm2reg_M,
    input  wire        we_reg_M,
    input  wire [1:0]  hilo_mux_ctrl_M,
    input  wire        jal_M,
    input  wire        valid_M,

    input  wire [31:0] alu_out_M,
    input  wire [31:0] rd_dm_M,
    input  wire [4:0]  write_reg_M,
    input  wire [31:0] pc_plus4_M,
    input  wire [31:0] hi_out_M,
    input  wire [31:0] lo_out_M,

    output reg         dm2reg_W,
    output reg         we_reg_W,
    output reg  [1:0]  hilo_mux_ctrl_W,
    output reg         jal_W,
    output reg         valid_W,

    output reg  [31:0] alu_out_W,
    output reg  [31:0] rd_dm_W,
    output reg  [4:0]  write_reg_W,
    output reg  [31:0] pc_plus4_W,
    output reg  [31:0] hi_out_W,
    output reg  [31:0] lo_out_W
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dm2reg_W       <= 1'b0;
            we_reg_W       <= 1'b0;
            hilo_mux_ctrl_W <= 2'b0;
            jal_W          <= 1'b0;
            valid_W        <= 1'b0;

            alu_out_W      <= 32'b0;
            rd_dm_W        <= 32'b0;
            write_reg_W    <= 5'b0;
            pc_plus4_W     <= 32'b0;
            hi_out_W       <= 32'b0;
            lo_out_W       <= 32'b0;
        end
        else begin
            dm2reg_W       <= dm2reg_M;
            we_reg_W       <= we_reg_M;
            hilo_mux_ctrl_W <= hilo_mux_ctrl_M;
            jal_W          <= jal_M;
            valid_W        <= valid_M;

            alu_out_W      <= alu_out_M;
            rd_dm_W        <= rd_dm_M;
            write_reg_W    <= write_reg_M;
            pc_plus4_W     <= pc_plus4_M;
            hi_out_W       <= hi_out_M;
            lo_out_W       <= lo_out_M;
        end
    end

endmodule