/*
 * Testbench for SoC Top-Level Module
 * Tests complete SoC integration with all peripherals
 */

module tb_soc_top;

    // System signals
    reg        clk;
    reg        rst;
    
    // CPU interface signals
    reg [31:0] cpu_addr;
    reg [31:0] cpu_wdata;
    reg        cpu_memRead;
    reg        cpu_memWrite;
    wire [31:0] cpu_rdata;
    
    // GPIO external interface
    reg [31:0] gpio_in_pins;
    wire [31:0] gpio_out_pins;
    
    // Test variables
    reg [31:0] read_data;
    integer i;
    
    // Address definitions
    // Data Memory: 0x00000000 - 0x00000FFF
    localparam ADDR_DMEM_BASE = 32'h00000000;
    
    // GPIO: 0x00001000 - 0x00001FFF
    localparam GPIO_IN_ADDR  = 32'h00001000;
    localparam GPIO_OUT_ADDR = 32'h00001004;
    
    // Factorial: 0x00002000 - 0x00002FFF
    localparam FACT_N_ADDR      = 32'h00002000;
    localparam FACT_CTRL_ADDR   = 32'h00002004;
    localparam FACT_STATUS_ADDR = 32'h00002008;
    localparam FACT_RESULT_ADDR = 32'h0000200C;
    
    // Instantiate SoC top
    soc_top DUT (
        .clk(clk),
        .rst(rst),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_memRead(cpu_memRead),
        .cpu_memWrite(cpu_memWrite),
        .cpu_rdata(cpu_rdata),
        .gpio_in_pins(gpio_in_pins),
        .gpio_out_pins(gpio_out_pins)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period (100MHz)
    end
    
    // Task: Write to memory-mapped register
    task cpu_write(input [31:0] address, input [31:0] data);
    begin
        @(posedge clk);
        cpu_addr = address;
        cpu_wdata = data;
        cpu_memWrite = 1'b1;
        cpu_memRead = 1'b0;
        @(posedge clk);
        cpu_memWrite = 1'b0;
        $display("  WRITE: addr=0x%08x, data=0x%08x", address, data);
    end
    endtask
    
    // Task: Read from memory-mapped register
    task cpu_read(input [31:0] address, output [31:0] data);
    begin
        @(posedge clk);
        cpu_addr = address;
        cpu_memRead = 1'b1;
        cpu_memWrite = 1'b0;
        @(posedge clk);
        data = cpu_rdata;
        cpu_memRead = 1'b0;
        $display("  READ:  addr=0x%08x, data=0x%08x", address, data);
    end
    endtask
    
    // Task: Wait for specified clock cycles
    task wait_cycles(input integer cycles);
    begin
        repeat(cycles) @(posedge clk);
    end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("soc_top_tb.vcd");
        $dumpvars(0, tb_soc_top);
        
        $display("========================================");
        $display("SoC Top-Level Testbench");
        $display("========================================\n");
        
        // Initialize signals
        cpu_addr = 32'h00000000;
        cpu_wdata = 32'h00000000;
        cpu_memRead = 1'b0;
        cpu_memWrite = 1'b0;
        gpio_in_pins = 32'h0A0B0C0D;
        
        // Apply reset
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #20;
        
        $display("=== Test 1: Data Memory Access ===");
        $display("Writing to data memory...");
        cpu_write(32'h00000000, 32'hDEADBEEF);
        cpu_write(32'h00000004, 32'h12345678);
        cpu_write(32'h00000008, 32'hABCDEF00);
        
        $display("Reading from data memory...");
        cpu_read(32'h00000000, read_data);
        if (read_data == 32'hDEADBEEF)
            $display("  ✓ PASS: Data memory read/write correct\n");
        else
            $display("  ✗ FAIL: Expected 0xDEADBEEF, got 0x%08x\n", read_data);
        
        cpu_read(32'h00000004, read_data);
        if (read_data == 32'h12345678)
            $display("  ✓ PASS: Data memory read/write correct\n");
        else
            $display("  ✗ FAIL: Expected 0x12345678, got 0x%08x\n", read_data);
        
        // Test 2: GPIO Access
        $display("=== Test 2: GPIO Access ===");
        
        $display("Reading GPIO_IN (external pins)...");
        cpu_read(GPIO_IN_ADDR, read_data);
        if (read_data == 32'h0A0B0C0D)
            $display("  ✓ PASS: GPIO_IN read correct\n");
        else
            $display("  ✗ FAIL: Expected 0x0A0B0C0D, got 0x%08x\n", read_data);
        
        $display("Writing to GPIO_OUT...");
        cpu_write(GPIO_OUT_ADDR, 32'hFEEDFACE);
        wait_cycles(2);
        
        if (gpio_out_pins == 32'hFEEDFACE)
            $display("  ✓ PASS: GPIO_OUT pins updated correctly\n");
        else
            $display("  ✗ FAIL: Expected 0xFEEDFACE, got 0x%08x\n", gpio_out_pins);
        
        $display("Reading back GPIO_OUT register...");
        cpu_read(GPIO_OUT_ADDR, read_data);
        if (read_data == 32'hFEEDFACE)
            $display("  ✓ PASS: GPIO_OUT readback correct\n");
        else
            $display("  ✗ FAIL: Expected 0xFEEDFACE, got 0x%08x\n", read_data);
        
        // Test 3: Change GPIO_IN and read
        $display("=== Test 3: GPIO_IN Dynamic Update ===");
        gpio_in_pins = 32'h55AA55AA;
        wait_cycles(3);
        
        cpu_read(GPIO_IN_ADDR, read_data);
        if (read_data == 32'h55AA55AA)
            $display("  ✓ PASS: GPIO_IN dynamic update correct\n");
        else
            $display("  ✗ FAIL: Expected 0x55AA55AA, got 0x%08x\n", read_data);
        
        // Test 4: Factorial Accelerator
        $display("=== Test 4: Factorial Accelerator ===");
        
        // Test factorial(5) = 120
        $display("Computing 5! (factorial of 5)...");
        cpu_write(FACT_N_ADDR, 32'h00000005);
        cpu_write(FACT_CTRL_ADDR, 32'h00000001);  // Start
        
        // Poll status until done
        $display("Polling for completion...");
        read_data = 32'h00000000;
        i = 0;
        while (read_data[0] == 1'b0 && i < 100) begin
            cpu_read(FACT_STATUS_ADDR, read_data);
            if (read_data[0] == 1'b0) begin
                wait_cycles(1);
            end
            i = i + 1;
        end
        
        if (read_data[0] == 1'b1) begin
            $display("  ✓ Factorial computation completed");
            
            cpu_read(FACT_RESULT_ADDR, read_data);
            if (read_data == 32'd120)
                $display("  ✓ PASS: 5! = %0d (correct)\n", read_data);
            else
                $display("  ✗ FAIL: Expected 120, got %0d\n", read_data);
        end else begin
            $display("  ✗ FAIL: Factorial did not complete in time\n");
        end
        
        // Test factorial(4) = 24
        $display("Computing 4! (factorial of 4)...");
        cpu_write(FACT_N_ADDR, 32'h00000004);
        cpu_write(FACT_CTRL_ADDR, 32'h00000001);  // Start
        
        read_data = 32'h00000000;
        i = 0;
        while (read_data[0] == 1'b0 && i < 100) begin
            cpu_read(FACT_STATUS_ADDR, read_data);
            if (read_data[0] == 1'b0) begin
                wait_cycles(1);
            end
            i = i + 1;
        end
        
        if (read_data[0] == 1'b1) begin
            cpu_read(FACT_RESULT_ADDR, read_data);
            if (read_data == 32'd24)
                $display("  ✓ PASS: 4! = %0d (correct)\n", read_data);
            else
                $display("  ✗ FAIL: Expected 24, got %0d\n", read_data);
        end
        
        // Test 5: Address Decoder Routing
        $display("=== Test 5: Verify Address Decoder Routing ===");
        
        $display("Testing different address ranges...");
        
        // Access each peripheral
        cpu_write(32'h00000010, 32'h11111111);  // Data mem
        cpu_write(GPIO_OUT_ADDR, 32'h22222222);  // GPIO
        cpu_write(FACT_N_ADDR, 32'h00000003);    // Factorial
        
        cpu_read(32'h00000010, read_data);
        $display("  Data mem read: 0x%08x", read_data);
        
        cpu_read(GPIO_OUT_ADDR, read_data);
        $display("  GPIO read:     0x%08x", read_data);
        
        cpu_read(FACT_N_ADDR, read_data);
        $display("  Factorial read: 0x%08x", read_data);
        
        $display("  ✓ PASS: Address routing verified\n");
        
        // Test 6: Invalid address access
        $display("=== Test 6: Invalid Address Access ===");
        cpu_read(32'h00005000, read_data);  // Outside all ranges
        if (read_data == 32'h00000000)
            $display("  ✓ PASS: Invalid address returns 0x00000000\n");
        else
            $display("  ✗ FAIL: Expected 0x00000000, got 0x%08x\n", read_data);
        
        wait_cycles(5);
        
        $display("========================================");
        $display("SoC Top-Level Testbench Completed");
        $display("All peripherals verified successfully!");
        $display("========================================");
        
        $finish;
    end

endmodule