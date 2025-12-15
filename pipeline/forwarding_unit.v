

module forwarding_unit (

    input  wire [4:0]  rs_E,
    input  wire [4:0]  rt_E,

    input  wire [4:0]  write_reg_M,
    input  wire        we_reg_M,

    input  wire [4:0]  write_reg_W,
    input  wire        we_reg_W,

    output wire [1:0]  forward_A,
    output wire [1:0]  forward_B
);

    reg [1:0] forward_A_sel;

    always @(*) begin

        forward_A_sel = 2'b00;

        if (we_reg_M && (write_reg_M != 5'b0) && (write_reg_M == rs_E)) begin
            forward_A_sel = 2'b10;
        end

        else if (we_reg_W && (write_reg_W != 5'b0) && (write_reg_W == rs_E)) begin
            forward_A_sel = 2'b01;
        end
    end

    assign forward_A = forward_A_sel;

    reg [1:0] forward_B_sel;

    always @(*) begin

        forward_B_sel = 2'b00;

        if (we_reg_M && (write_reg_M != 5'b0) && (write_reg_M == rt_E)) begin
            forward_B_sel = 2'b10;
        end

        else if (we_reg_W && (write_reg_W != 5'b0) && (write_reg_W == rt_E)) begin
            forward_B_sel = 2'b01;
        end
    end

    assign forward_B = forward_B_sel;

endmodule