

module factorial_wrapper (

    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        memRead,
    input  wire        memWrite
);

    localparam FACT_N_ADDR      = 32'h00002000;
    localparam FACT_CTRL_ADDR   = 32'h00002004;
    localparam FACT_STATUS_ADDR = 32'h00002008;
    localparam FACT_RESULT_ADDR = 32'h0000200C;

    reg [3:0]  n_reg;
    reg        start_pulse;
    reg [31:0] result_reg;
    reg        status_reg;

    wire        fact_done;
    wire [31:0] fact_result;
    wire [3:0]  fact_n;
    wire        fact_go;

    assign fact_n = n_reg;
    assign fact_go = start_pulse;

    factorial_accelerator factorial_accel (
        .clk(clk),
        .reset(rst),
        .go(fact_go),
        .n(fact_n),
        .result(fact_result),
        .done(fact_done),
        .error()
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            n_reg       <= 4'h0;
            start_pulse <= 1'b0;
        end else begin

            start_pulse <= 1'b0;

            if (memWrite) begin
                case (addr)
                    FACT_N_ADDR: begin

                        n_reg <= wdata[3:0];
                    end

                    FACT_CTRL_ADDR: begin

                        if (wdata[0]) begin
                            start_pulse <= 1'b1;
                        end
                    end

                    default: begin

                    end
                endcase
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_reg <= 1'b0;
            result_reg <= 32'h00000000;
        end else begin

            if (memWrite && (addr == FACT_CTRL_ADDR) && wdata[0])
                status_reg <= 1'b0;

            else if (fact_done)
                status_reg <= 1'b1;

            if (fact_done) begin
                result_reg <= fact_result;
            end
        end
    end

    always @(*) begin
        rdata = 32'h00000000;

        if (memRead) begin
            case (addr)
                FACT_N_ADDR:      rdata = {28'b0, n_reg};
                FACT_CTRL_ADDR:   rdata = {31'b0, start_pulse};
                FACT_STATUS_ADDR: rdata = {31'b0, status_reg};
                FACT_RESULT_ADDR: rdata = result_reg;
                default:          rdata = 32'h00000000;
            endcase
        end
    end

endmodule