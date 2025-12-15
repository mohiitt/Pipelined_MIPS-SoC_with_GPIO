

module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        flush,

    input  wire [31:0] instr_F,
    input  wire [31:0] pc_plus4_F,

    output reg  [31:0] instr_D,
    output reg  [31:0] pc_plus4_D,
    output reg         valid_D
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_D   <= 32'b0;
            pc_plus4_D <= 32'b0;
            valid_D    <= 1'b0;
        end
        else if (flush) begin

            instr_D   <= 32'b0;
            pc_plus4_D <= 32'b0;
            valid_D    <= 1'b0;
        end
        else if (enable) begin

            instr_D   <= instr_F;
            pc_plus4_D <= pc_plus4_F;
            valid_D    <= 1'b1;
        end

    end

endmodule