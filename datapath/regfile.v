module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  ra3,
    input  wire [4:0]  wa,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    output wire [31:0] rd3,
    input  wire        rst
);

    reg [31:0] rf [0:31];
    integer n;

    // Initialize logic
    initial begin
        for (n = 0; n < 32; n = n + 1) rf[n] = 32'h0;
        rf[29] = 32'h100; // Initialize stack pointer
    end

    // Sequential write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (n = 0; n < 32; n = n + 1) rf[n] = 32'h0;
            rf[29] = 32'h100;
        end
        else if (we && wa != 0) begin
            rf[wa] <= wd;
        end
    end

    // Combinational read with internal bypass
    // If reading same register as being written in this cycle (from WB),
    // use the write data 'wd' directly.
    wire [31:0] bypass_rd1 = (ra1 == 0) ? 0 : (we && wa == ra1) ? wd : rf[ra1];
    wire [31:0] bypass_rd2 = (ra2 == 0) ? 0 : (we && wa == ra2) ? wd : rf[ra2];
    wire [31:0] bypass_rd3 = (ra3 == 0) ? 0 : (we && wa == ra3) ? wd : rf[ra3];

    assign rd1 = bypass_rd1;
    assign rd2 = bypass_rd2;
    assign rd3 = bypass_rd3;

endmodule