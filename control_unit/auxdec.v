module auxdec (
    input  wire [1:0] alu_op,
    input  wire [5:0] funct,
    output wire [3:0] alu_ctrl,
    output wire          jr,
    output wire          hilo_wd,
    output wire [1:0] hilo_mux_ctrl
);

    reg [3:0] ctrl;
    reg       jr_r;
    reg       hilo_wd_r;
    reg [1:0] hilo_mux_r;

    assign alu_ctrl = ctrl;
    assign jr = jr_r;
    assign hilo_wd = hilo_wd_r;
    assign hilo_mux_ctrl = hilo_mux_r;

    always @(*) begin

    ctrl = 4'b0010;
    jr_r = 1'b0;
    hilo_wd_r = 1'b0;
    hilo_mux_r = 2'b00;

    case (alu_op)
        2'b00: begin
            ctrl = 4'b0010;
            hilo_mux_r = 2'b00;
        end
        2'b01: begin
            ctrl = 4'b0110;
            hilo_mux_r = 2'b00;
        end
        default: begin
            case (funct)
                6'b10_0100: begin
                    ctrl = 4'b0000;
                    hilo_mux_r = 2'b00;
                end
                6'b10_0101: begin
                    ctrl = 4'b0001;
                    hilo_mux_r = 2'b00;
                end
                6'b10_0000: begin
                    ctrl = 4'b0010;
                    hilo_mux_r = 2'b00;
                end
                6'b10_0010: begin
                    ctrl = 4'b0110;
                    hilo_mux_r = 2'b00;
                end
                6'b10_1010: begin
                    ctrl = 4'b0111;
                    hilo_mux_r = 2'b00;
                end
                6'b01_1001: begin
                    ctrl = 4'b0011;
                    hilo_wd_r = 1'b1;
                    hilo_mux_r = 2'b00;
                end
                6'b01_0000: begin
                    ctrl = 4'b0100;
                    hilo_mux_r = 2'b01;
                end
                6'b01_0010: begin
                    ctrl = 4'b0101;
                    hilo_mux_r = 2'b10;
                end
                6'b00_0000: begin
                    ctrl = 4'b1000;
                    hilo_mux_r = 2'b00;
                end
                6'b00_0010: begin
                    ctrl = 4'b1001;
                    hilo_mux_r = 2'b00;
                end
                6'b00_1000: begin
                    ctrl = 4'b0010;
                    jr_r = 1'b1;
                    hilo_mux_r = 2'b00;
                end
                default: begin
                    ctrl = 4'b0010;
                    hilo_mux_r = 2'b00;
                end
            endcase
        end
    endcase
end
		        endmodule