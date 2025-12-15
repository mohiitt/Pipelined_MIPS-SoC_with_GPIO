

module hazard_unit(

    input [4:0] RsD, RtD,
    input [4:0] RsE, RtE,
    input [4:0] wa_reg_E,
    input [4:0] wa_reg_M,
    input [4:0] wa_reg_W,
    input we_reg_E, we_reg_M, we_reg_W,
    input dm2reg_E, dm2reg_M,
    input BranchD,
    input JumpD,
    input JumpRegD,
    input [5:0] OpcodeD, FunctD,
    input clk, rst,

    output reg StallF,
    output reg StallD,
    output reg FlushE,
    output reg FlushD,
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE
);

wire lwstall;
assign lwstall = dm2reg_E &&
                 ((wa_reg_E == RsD) || (wa_reg_E == RtD)) &&
                 (wa_reg_E != 0);

reg [1:0] mult_cnt;
wire is_mult_D = (OpcodeD == 6'b000000 && FunctD == 6'b011001);
wire mult_stall = is_mult_D && (mult_cnt < 3);

always @(posedge clk or posedge rst) begin
    if (rst) mult_cnt <= 0;
    else if (mult_stall) mult_cnt <= mult_cnt + 1;
    else mult_cnt <= 0;
end

wire control_flush;
assign control_flush = (BranchD || JumpD || JumpRegD);

always @(*) begin

    StallF = 0;
    StallD = 0;
    FlushE = 0;
    FlushD = 0;

    if (lwstall) begin
        StallF = 1;
        StallD = 1;
        FlushE = 1;
    end

    if (mult_stall) begin
        StallF = 1;
        StallD = 1;
        FlushE = 1;
    end

    if (control_flush && !StallD) begin
        FlushD = 1;
    end
end

always @(*) begin

    if (we_reg_M && (wa_reg_M != 0) && (wa_reg_M == RsE))
        ForwardAE = 2'b10;

    else if (we_reg_W && (wa_reg_W != 0) && (wa_reg_W == RsE))
        ForwardAE = 2'b01;
    else
        ForwardAE = 2'b00;

    if (we_reg_M && (wa_reg_M != 0) && (wa_reg_M == RtE))
        ForwardBE = 2'b10;
    else if (we_reg_W && (wa_reg_W != 0) && (wa_reg_W == RtE))
        ForwardBE = 2'b01;
    else
        ForwardBE = 2'b00;
end

endmodule