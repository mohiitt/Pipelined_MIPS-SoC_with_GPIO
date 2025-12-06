/*
 * Factorial Accelerator Memory-Mapped Wrapper (corrected)
 *
 * Memory Map (32-bit aligned):
 * 0x00002000 - FACT_N_ADDR      (R/W): Input value n (4-bit)
 * 0x00002004 - FACT_CTRL_ADDR   (W)  : Control register (bit0 = start)
 * 0x00002008 - FACT_STATUS_ADDR (R)  : Status register (bit0 = done)
 * 0x0000200C - FACT_RESULT_ADDR (R)  : Result register (32-bit factorial)
 *
 * Notes:
 * - The wrapper generates a single-cycle 'go' pulse for the accelerator
 *   when CPU writes FACT_CTRL with bit0 = 1.
 * - Status/result are sampled from the accelerator.
 */

module factorial_wrapper (
    // System interface
    input  wire        clk,
    input  wire        rst,

    // Memory-mapped interface (CPU-independent)
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        memRead,
    input  wire        memWrite
);

    // Memory-mapped register addresses
    localparam FACT_N_ADDR      = 32'h00002000;  // Input n register
    localparam FACT_CTRL_ADDR   = 32'h00002004;  // Control register (start)
    localparam FACT_STATUS_ADDR = 32'h00002008;  // Status register (done)
    localparam FACT_RESULT_ADDR = 32'h0000200C;  // Result register

    // Internal registers
    reg [3:0]  n_reg;         // Input value n (4-bit)
    reg        start_pulse;   // One-cycle start pulse to accelerator (synchronous)
    reg [31:0] result_reg;    // 32-bit result
    reg        status_reg;    // Done status (sampled from accelerator)

    // Accelerator interface wires
    wire        fact_done;
    wire [31:0] fact_result;
    wire [3:0]  fact_n;
    wire        fact_go;

    // Connect n to accelerator input
    assign fact_n = n_reg;
    assign fact_go = start_pulse;

    // Instantiate the factorial accelerator (user-supplied)
    factorial_accelerator factorial_accel (
        .clk(clk),
        .reset(rst),
        .go(fact_go),
        .n(fact_n),
        .result(fact_result),
        .done(fact_done),
        .error()  // unused
    );

    // Write logic: collect CPU writes and generate a synchronous 1-cycle start pulse
    // start_pulse is asserted for exactly one clock when CPU writes CTRL with bit0=1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            n_reg       <= 4'h0;
            start_pulse <= 1'b0;
        end else begin
            // default clear the pulse; only assert when memWrite to CTRL in same cycle
            start_pulse <= 1'b0;

            if (memWrite) begin
                case (addr)
                    FACT_N_ADDR: begin
                        // store lower 4 bits of wdata
                        n_reg <= wdata[3:0];
                    end

                    FACT_CTRL_ADDR: begin
                        // generate single-cycle start pulse if bit0==1
                        if (wdata[0]) begin
                            start_pulse <= 1'b1;
                        end
                    end

                    default: begin
                        // ignore writes to other addresses
                    end
                endcase
            end
        end
    end

    // Sample accelerator status/result into wrapper registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_reg <= 1'b0;
            result_reg <= 32'h00000000;
        end else begin
            status_reg <= fact_done;
            if (fact_done) begin
                result_reg <= fact_result;
            end
        end
    end

    // Combinational read-mux
    always @(*) begin
        rdata = 32'h00000000; // default

        if (memRead) begin
            case (addr)
                FACT_N_ADDR:      rdata = {28'b0, n_reg};               // zero-extend n
                FACT_CTRL_ADDR:   rdata = {31'b0, start_pulse};        // start (for debug)
                FACT_STATUS_ADDR: rdata = {31'b0, status_reg};         // done bit
                FACT_RESULT_ADDR: rdata = result_reg;                  // factorial result
                default:          rdata = 32'h00000000;
            endcase
        end
    end

endmodule
