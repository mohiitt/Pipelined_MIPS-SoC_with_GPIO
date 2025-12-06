/*
 * Testbench for GPIO Module
 * Tests memory-mapped GPIO read/write operations
 */

module tb_gpio;

    // Testbench signals
    reg        clk;
    reg        rst;
    reg [31:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;
    reg        memRead;
    reg        memWrite;
    
    // GPIO external interface
    reg [31:0] gpio_in_pins;
    wire [31:0] gpio_out_pins;
    
    // GPIO register addresses (updated to match gpio.v)
    localparam GPIO_IN_ADDR  = 32'h00001000;
    localparam GPIO_OUT_ADDR = 32'h00001004;
    
    // Instantiate GPIO module
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end
    
    // Main test sequence
    initial begin
        $dumpfile("gpio_tb.vcd");
        $dumpvars(0, tb_gpio);
        
        $display("========================================");
        $display("Starting GPIO Testbench...");
        $display("========================================");
        
        // Initialize signals
        clk = 0;
        addr = 0;
        wdata = 0;
        memRead = 0;
        memWrite = 0;
        gpio_in_pins = 32'h12345678;
        
        // Reset
        #10 rst = 0;
        #10;
        
        // Test 1: Read GPIO_IN register
        $display("Test 1: Reading GPIO_IN register");
        addr = GPIO_IN_ADDR;
        memRead = 1;
        #10;
        $display("GPIO_IN read: Expected=0x12345678, Actual=0x%08x", rdata);
        memRead = 0;
        #10;
        
        // Test 2: Write to GPIO_OUT register
        $display("Test 2: Writing to GPIO_OUT register");
        addr = GPIO_OUT_ADDR;
        wdata = 32'hDEADBEEF;
        memWrite = 1;
        #10;
        memWrite = 0;
        $display("GPIO_OUT write: Expected=0xDEADBEEF, Actual=0x%08x", gpio_out_pins);
        #10;
        
        // Test 3: Read GPIO_OUT register (verification)
        $display("Test 3: Reading GPIO_OUT register for verification");
        addr = GPIO_OUT_ADDR;
        memRead = 1;
        #10;
        $display("GPIO_OUT read: Expected=0xDEADBEEF, Actual=0x%08x", rdata);
        memRead = 0;
        #10;
        
        // Test 4: Change GPIO_IN pins and read
        $display("Test 4: Changing GPIO_IN pins and reading");
        gpio_in_pins = 32'hABCDEF00;
        #20; // Wait for synchronization
        addr = GPIO_IN_ADDR;
        memRead = 1;
        #10;
        $display("GPIO_IN read after change: Expected=0xABCDEF00, Actual=0x%08x", rdata);
        memRead = 0;
        #10;
        
        // Test 5: Attempt to write to GPIO_IN (should be ignored)
        $display("Test 5: Attempting to write to GPIO_IN (should be ignored)");
        addr = GPIO_IN_ADDR;
        wdata = 32'hFFFFFFFF;
        memWrite = 1;
        #10;
        memWrite = 0;
        #10;
        // Read GPIO_IN to verify write was ignored
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
    
    // Monitor changes (optional, can comment out for cleaner output)
    // initial begin
    //     $monitor("Time=%0t, addr=0x%08x, wdata=0x%08x, rdata=0x%08x, memRead=%b, memWrite=%b, gpio_in=0x%08x, gpio_out=0x%08x", 
    //              $time, addr, wdata, rdata, memRead, memWrite, gpio_in_pins, gpio_out_pins);
    // end

endmodule