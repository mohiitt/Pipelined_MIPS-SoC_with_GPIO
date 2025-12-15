

module tb_addr_decoder;

    reg [31:0] addr;
    reg        memRead;
    reg        memWrite;

    reg [31:0] rdata_data_mem;
    reg [31:0] rdata_gpio;
    reg [31:0] rdata_fact;

    wire       cs_data_mem;
    wire       cs_gpio;
    wire       cs_fact;

    wire [31:0] rdata_out;

    localparam ADDR_DATA_MEM = 32'h00000100;
    localparam ADDR_GPIO     = 32'h00001000;
    localparam ADDR_FACT     = 32'h00002000;
    localparam ADDR_INVALID  = 32'h00003000;

    integer one_hot_pass;
    reg [31:0] test_addrs [0:3];
    integer i;

    addr_decoder DUT (
        .addr(addr),
        .memRead(memRead),
        .memWrite(memWrite),
        .rdata_data_mem(rdata_data_mem),
        .rdata_gpio(rdata_gpio),
        .rdata_fact(rdata_fact),
        .cs_data_mem(cs_data_mem),
        .cs_gpio(cs_gpio),
        .cs_fact(cs_fact),
        .rdata_out(rdata_out)
    );

    task test_chip_select;
        input [31:0] test_addr;
        input [2:0] expected_cs;
        input [8*32:1] range_name;
    begin
        addr = test_addr;
        memRead = 1'b1;
        memWrite = 1'b0;
        #10;

        $display("Test: %s (addr=0x%08x)", range_name, test_addr);
        $display("  Expected CS: [data_mem=%b, gpio=%b, fact=%b]", expected_cs[2], expected_cs[1], expected_cs[0]);
        $display("  Actual CS:   [data_mem=%b, gpio=%b, fact=%b]", cs_data_mem, cs_gpio, cs_fact);

        if ({cs_data_mem, cs_gpio, cs_fact} == expected_cs) begin
            $display("  ✓ PASS: Chip selects correct");
        end else begin
            $display("  ✗ FAIL: Chip selects mismatch!");
        end
        $display("");
    end
    endtask

    task test_read_mux;
        input [31:0] test_addr;
        input [31:0] expected_data;
        input [8*32:1] range_name;
    begin
        addr = test_addr;
        memRead = 1'b1;
        memWrite = 1'b0;
        #10;

        $display("Test: Read from %s (addr=0x%08x)", range_name, test_addr);
        $display("  Expected rdata: 0x%08x", expected_data);
        $display("  Actual rdata:   0x%08x", rdata_out);

        if (rdata_out == expected_data) begin
            $display("  ✓ PASS: Read data mux correct");
        end else begin
            $display("  ✗ FAIL: Read data mismatch!");
        end
        $display("");
    end
    endtask

    initial begin
        $dumpfile("addr_decoder_tb.vcd");
        $dumpvars(0, tb_addr_decoder);

        $display("========================================");
        $display("Address Decoder Testbench");
        $display("========================================\n");

        addr = 32'h00000000;
        memRead = 1'b0;
        memWrite = 1'b0;
        rdata_data_mem = 32'hDEADBEEF;
        rdata_gpio = 32'h12345678;
        rdata_fact = 32'hABCDEF00;

        #20;

        $display("=== Test 1: Chip Select Generation ===\n");

        test_chip_select(ADDR_DATA_MEM, 3'b100, "Data Memory");
        test_chip_select(ADDR_GPIO,     3'b010, "GPIO");
        test_chip_select(ADDR_FACT,     3'b001, "Factorial");
        test_chip_select(ADDR_INVALID,  3'b000, "Invalid Address");

        $display("=== Test 2: Chip Selects with No Access ===\n");
        addr = ADDR_DATA_MEM;
        memRead = 1'b0;
        memWrite = 1'b0;
        #10;

        $display("Test: Data mem address with memRead=0, memWrite=0");
        $display("  Expected CS: [data_mem=0, gpio=0, fact=0]");
        $display("  Actual CS:   [data_mem=%b, gpio=%b, fact=%b]", cs_data_mem, cs_gpio, cs_fact);

        if ({cs_data_mem, cs_gpio, cs_fact} == 3'b000) begin
            $display("  ✓ PASS: Chip selects inactive as expected\n");
        end else begin
            $display("  ✗ FAIL: Chip selects should be inactive!\n");
        end

        $display("=== Test 3: Read Data Multiplexing ===\n");

        test_read_mux(ADDR_DATA_MEM, 32'hDEADBEEF, "Data Memory");
        test_read_mux(ADDR_GPIO,     32'h12345678, "GPIO");
        test_read_mux(ADDR_FACT,     32'hABCDEF00, "Factorial");
        test_read_mux(ADDR_INVALID,  32'h00000000, "Invalid Address");

        $display("=== Test 4: Chip Selects on Write ===\n");

        addr = ADDR_GPIO;
        memRead = 1'b0;
        memWrite = 1'b1;
        #10;

        $display("Test: GPIO write operation");
        $display("  Expected CS: [data_mem=0, gpio=1, fact=0]");
        $display("  Actual CS:   [data_mem=%b, gpio=%b, fact=%b]", cs_data_mem, cs_gpio, cs_fact);

        if (cs_gpio == 1'b1 && cs_data_mem == 1'b0 && cs_fact == 1'b0) begin
            $display("  ✓ PASS: GPIO chip select active on write\n");
        end else begin
            $display("  ✗ FAIL: Chip select behavior incorrect on write!\n");
        end

        $display("=== Test 5: One-Hot Chip Select Verification ===\n");

        one_hot_pass = 1;
        test_addrs[0] = ADDR_DATA_MEM;
        test_addrs[1] = ADDR_GPIO;
        test_addrs[2] = ADDR_FACT;
        test_addrs[3] = ADDR_INVALID;
        memRead = 1'b1;
        memWrite = 1'b0;
        for (i = 0; i < 4; i = i + 1) begin
            addr = test_addrs[i];
            #10;

            if ((cs_data_mem + cs_gpio + cs_fact) > 1) begin
                one_hot_pass = 0;
            end
        end
        if (one_hot_pass == 1)
            $display("  ✓ PASS: One-hot property verified (max 1 CS active)\n");
        else
            $display("  ✗ FAIL: One-hot property violated!\n");

        $display("========================================");
        $display("Address Decoder Testbench Completed");
        $display("========================================");

        $finish;
    end

endmodule