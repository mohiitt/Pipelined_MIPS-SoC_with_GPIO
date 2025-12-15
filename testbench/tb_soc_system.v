// ============================================================================
// Testbench for Integrated SoC System
// Verifies MIPS pipeline interaction with SoC peripherals (GPIO, Factorial)
// ============================================================================

module tb_soc_system;

    // Clock and reset
    reg         clk;
    reg         rst;
    reg  [4:0]  ra3;
    
    // GPIO Interface
    reg  [31:0] gpio_in;
    wire [31:0] gpio_out;
    
    // Cycle counter
    integer cycle_count;
    
    // Instantiate Integrated SoC Top
    soc_system_top DUT (
        .clk(clk),
        .rst(rst),
        .ra3(ra3),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    // ========================================
    // Debug Signals for Pipeline Visualization
    // ========================================
    
    // IF Stage
    wire [31:0] debug_pc_F;
    wire [31:0] debug_instr_F;
    assign debug_pc_F    = DUT.cpu.dp.pc_F;
    assign debug_instr_F = DUT.cpu.dp.instr_F;
    
    // ID Stage
    wire [31:0] debug_pc_D;
    wire [31:0] debug_instr_D;
    assign debug_pc_D    = DUT.cpu.dp.pc_plus4_D; // Showing PC+4
    assign debug_instr_D = DUT.cpu.dp.instr_D;
    
    // EX Stage
    wire [31:0] debug_pc_E;
    wire [31:0] debug_alu_out_E;
    wire [4:0]  debug_rs_E;
    wire [4:0]  debug_rt_E;
    assign debug_pc_E      = DUT.cpu.dp.pc_plus4_E;
    assign debug_alu_out_E = DUT.cpu.dp.alu_out_E;
    assign debug_rs_E      = DUT.cpu.dp.rs_E;
    assign debug_rt_E      = DUT.cpu.dp.rt_E;
    
    // MEM Stage
    wire [31:0] debug_pc_M;
    wire [31:0] debug_alu_out_M;
    wire [31:0] debug_write_data_M;
    assign debug_pc_M         = DUT.cpu.dp.pc_plus4_M;
    assign debug_alu_out_M    = DUT.cpu.dp.alu_out_M;
    assign debug_write_data_M = DUT.cpu.dp.wd_dm_M;
    
    // WB Stage
    wire [31:0] debug_pc_W;
    wire [31:0] debug_write_data_W;
    wire [4:0]  debug_rd_W;
    assign debug_pc_W         = DUT.cpu.dp.pc_plus4_W;
    assign debug_write_data_W = DUT.cpu.dp.result_W; // Result being written back
    assign debug_rd_W         = DUT.cpu.dp.write_reg_W; // Dest register address
    
    // Control Signals
    wire debug_stall_F;
    wire debug_stall_D;
    wire debug_flush_E;
    wire debug_flush_D;
    assign debug_stall_F = DUT.cpu.dp.stall_F;
    assign debug_stall_D = DUT.cpu.dp.stall_D;
    assign debug_flush_E = DUT.cpu.dp.flush_E;
    assign debug_flush_D = DUT.cpu.dp.flush_D;

    
    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Cycle Counter
    initial cycle_count = 0;
    always @(posedge clk) begin
        if (!rst) cycle_count = cycle_count + 1;
        else cycle_count = 0;
    end

    // Main Test Sequence
    initial begin
        $dumpfile("soc_system_tb.vcd");
        $dumpvars(0, tb_soc_system);
        
        $display("========================================");
        $display("Integrated SoC System Testbench");
        $display("========================================");
        $display("Instruction: LW from GPIO -> Calculate Factorial -> Output to GPIO");
        
        // Initialize
        rst = 1;
        ra3 = 0;
        gpio_in = 32'd5; // Set Input N = 5
        
        // Reset sequence
        #15;
        rst = 0;
        
        $display("\n[Use Case] Calculating 5! (Factorial of 5)...");
        $display("GPIO Input (N) = %d", gpio_in);
        
        // Wait for completion (Timeout 2000 cycles)
        fork
            begin: wait_loop
                // Check for GPIO Output change (detected by polling in TB? No, just wait)
                // We expect 5! = 120 (0x78)
                wait(gpio_out == 32'd120);
                $display("\n[SUCCESS] GPIO Output updated to %d (Expected 120)", gpio_out);
                $display("Finished in %d cycles", cycle_count);
                
                // Verify register states
                #20;
                $display("\nFinal Register Dump:");
                ra3 = 8; #1; $display("  $8 (N)      = 0x%08h", DUT.cpu.rd3);
                ra3 = 9; #1; $display("  $9 (Const)  = 0x%08h", DUT.cpu.rd3);
                ra3 = 10; #1; $display("  $10 (Status)= 0x%08h", DUT.cpu.rd3);
                ra3 = 11; #1; $display("  $11 (Result)= 0x%08h", DUT.cpu.rd3);
                
                $display("========================================");
                $display("Test Passed!");
                $display("========================================");
                $finish;
            end
            
            begin: timeout
                #20000; // 2000 cycles * 10ns = 20000ns
                $display("\n[ERROR] Simulation Timeout! GPIO Output not updated.");
                $display("Current GPIO Output: %d", gpio_out);
                $display("Current PC: 0x%08h", DUT.pc);
                $finish;
            end
        join
    end

    // Monitor pipeline activity
    always @(negedge clk) begin
         $display("T:%4t PC:%04h I:%08h WD:%08h WE:%b MR:%b RD:%08h G:%08h", 
                  $time, DUT.pc, DUT.instr, DUT.write_data, DUT.mem_write, DUT.mem_read, DUT.read_data, gpio_out);
    end

endmodule
