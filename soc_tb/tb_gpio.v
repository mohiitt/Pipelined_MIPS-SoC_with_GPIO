

module tb_gpio;

    reg        clk;
    reg        rst;
    reg [31:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;
    reg        memRead;
    reg        memWrite;

    reg [31:0] gpio_in_pins;
    wire [31:0] gpio_out_pins;

    localparam GPIO_IN_ADDR  = 32'h00001000;
    localparam GPIO_OUT_ADDR = 32'h00001004;

    gpio dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .memRead(memRead),
        .memWrite(memWrite),
        .gpio_in_pins(gpio_in_pins),
        .gpio_out_pins(gpio_out_pins)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("gpio_tb.vcd");
        $dumpvars(0, tb_gpio);

        $display("========================================");
        $display("Starting GPIO Testbench...");
        $display("========================================");

        clk = 0;
        addr = 0;
        wdata = 0;
        memRead = 0;
        memWrite = 0;
        gpio_in_pins = 32'h12345678;

        #10 rst = 0;
        #10;

        $display("Test 1: Reading GPIO_IN register");
        addr = GPIO_IN_ADDR;
        memRead = 1;
        #10;
        $display("GPIO_IN read: Expected=0x12345678, Actual=0x%08x", rdata);
        memRead = 0;
        #10;

        $display("Test 2: Writing to GPIO_OUT register");
        addr = GPIO_OUT_ADDR;
        wdata = 32'hDEADBEEF;
        memWrite = 1;
        #10;
        memWrite = 0;
        $display("GPIO_OUT write: Expected=0xDEADBEEF, Actual=0x%08x", gpio_out_pins);
        #10;

        $display("Test 3: Reading GPIO_OUT register for verification");
        addr = GPIO_OUT_ADDR;
        memRead = 1;
        #10;
        $display("GPIO_OUT read: Expected=0xDEADBEEF, Actual=0x%08x", rdata);
        memRead = 0;
        #10;

        $display("Test 4: Changing GPIO_IN pins and reading");
        gpio_in_pins = 32'hABCDEF00;
        #20;
        addr = GPIO_IN_ADDR;
        memRead = 1;
        #10;
        $display("GPIO_IN read after change: Expected=0xABCDEF00, Actual=0x%08x", rdata);
        memRead = 0;
        #10;

        $display("Test 5: Attempting to write to GPIO_IN (should be ignored)");
        addr = GPIO_IN_ADDR;
        wdata = 32'hFFFFFFFF;
        memWrite = 1;
        #10;
        memWrite = 0;
        #10;

        memRead = 1;
        #10;
        $display("GPIO_IN after write attempt: Expected=0xABCDEF00, Actual=0x%08x", rdata);
        memRead = 0;

        #20;
        $display("========================================");
        $display("GPIO testbench completed successfully!");
        $display("========================================");
        $finish;
    end

endmodule