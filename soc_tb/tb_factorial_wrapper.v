

module tb_factorial_wrapper;

    reg         clk;
    reg         rst;

    reg  [31:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;
    reg         memRead;
    reg         memWrite;

    integer i;
    reg [31:0] read_value;
    reg [31:0] expected_result;

    localparam FACT_N_ADDR      = 32'h00002000;
    localparam FACT_CTRL_ADDR   = 32'h00002004;
    localparam FACT_STATUS_ADDR = 32'h00002008;
    localparam FACT_RESULT_ADDR = 32'h0000200C;

    localparam FACT_0 = 32'd1;
    localparam FACT_1 = 32'd1;
    localparam FACT_2 = 32'd2;
    localparam FACT_3 = 32'd6;
    localparam FACT_4 = 32'd24;
    localparam FACT_5 = 32'd120;

    factorial_wrapper DUT (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .memRead(memRead),
        .memWrite(memWrite)
    );

    task tick;
    begin
        clk = 1'b0; #5;
        clk = 1'b1; #5;
    end
    endtask

    task reset;
    begin
        rst = 1'b1; #5;
        rst = 1'b0; #5;
    end
    endtask

    task write_register(input [31:0] address, input [31:0] data);
    begin
        addr = address;
        wdata = data;
        memWrite = 1'b1;
        memRead = 1'b0;
        tick;
        memWrite = 1'b0;
        $display("WRITE: addr=0x%08x, data=0x%08x", address, data);
    end
    endtask

    task read_register(input [31:0] address, output [31:0] data);
    begin
        addr = address;
        memRead = 1'b1;
        memWrite = 1'b0;
        tick;
        data = rdata;
        memRead = 1'b0;
        $display("READ:  addr=0x%08x, data=0x%08x", address, data);
    end
    endtask

    task wait_for_done;
    begin
        read_value = 32'h00000000;
        while (read_value[0] == 1'b0) begin
            read_register(FACT_STATUS_ADDR, read_value);
            if (read_value[0] == 1'b0) begin
                tick;
            end
        end
        $display("Factorial computation completed (done=1)");
    end
    endtask

    task test_factorial(input [3:0] n_input, input [31:0] expected);
    begin
        $display("\n=== Testing Factorial(%0d) ===", n_input);

        write_register(FACT_N_ADDR, {28'h0000000, n_input});

        read_register(FACT_N_ADDR, read_value);
        if (read_value[3:0] == n_input) begin
            $display("✓ N register write/read successful");
        end else begin
            $display("✗ N register write/read failed: expected=%0d, got=%0d", n_input, read_value[3:0]);
        end

        write_register(FACT_CTRL_ADDR, 32'h00000001);

        wait_for_done;

        read_register(FACT_RESULT_ADDR, read_value);

        if (read_value == expected) begin
            $display("✓ Factorial(%0d) = %0d (PASS)", n_input, read_value);
        end else begin
            $display("✗ Factorial(%0d) = %0d, expected %0d (FAIL)", n_input, read_value, expected);
        end
    end
    endtask

    initial begin
        $dumpfile("factorial_wrapper_tb.vcd");
        $dumpvars(0, tb_factorial_wrapper);

        $display("========================================");
        $display("Starting Factorial Wrapper Testbench...");
        $display("========================================");

        clk = 1'b0;
        addr = 32'h00000000;
        wdata = 32'h00000000;
        memRead = 1'b0;
        memWrite = 1'b0;

        reset;
        $display("Reset applied");

        for (i = 0; i < 3; i = i + 1) begin
            tick;
        end

        $display("\n=== Testing Basic Register Access ===");

        read_register(FACT_N_ADDR, read_value);
        read_register(FACT_STATUS_ADDR, read_value);
        read_register(FACT_RESULT_ADDR, read_value);

        test_factorial(4'd0, FACT_0);
        test_factorial(4'd1, FACT_1);
        test_factorial(4'd2, FACT_2);
        test_factorial(4'd3, FACT_3);
        test_factorial(4'd4, FACT_4);
        test_factorial(4'd5, FACT_5);

        test_factorial(4'd6, 32'd720);

        $display("\n========================================");
        $display("Factorial Wrapper Testbench Completed");
        $display("========================================");

        $finish;
    end

endmodule