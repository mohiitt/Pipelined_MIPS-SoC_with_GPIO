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
    assign debug_pc_D    = DUT.cpu.dp.pc_plus4_D; 
    assign debug_instr_D = DUT.cpu.dp.instr_D;
    
    // EX Stage
    wire [31:0] debug_pc_E;
    wire [31:0] debug_alu_out_E;
    assign debug_pc_E      = DUT.cpu.dp.pc_plus4_E;
    assign debug_alu_out_E = DUT.cpu.dp.alu_out_E;
    
    // MEM Stage
    wire [31:0] debug_pc_M;
    wire [31:0] debug_alu_out_M;
    assign debug_pc_M         = DUT.cpu.dp.pc_plus4_M;
    assign debug_alu_out_M    = DUT.cpu.dp.alu_out_M;
    
    // WB Stage
    wire [31:0] debug_pc_W;
    wire [31:0] debug_write_data_W;
    assign debug_pc_W         = DUT.cpu.dp.pc_plus4_W;
    assign debug_write_data_W = DUT.cpu.dp.result_W; 
    
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
        
        // Reset
        rst = 1;
        gpio_in = 0;
        ra3 = 0;
        #10;
        rst = 0;
        
        $display("========================================");
        $display("Integrated SoC System Testbench");
        $display("========================================");

        // Pattern required by performance_analysis.py
        gpio_in = 32'd1; 
        
        fork
            begin
                // Wait for expected output - Pattern required by performance_analysis.py
                wait(gpio_out == 32'd1);
                
                $display("Finished in %d cycles", cycle_count);
                $display("[SUCCESS] GPIO Output updated to %d (Expected 1)", gpio_out);
                
                #100;
                $finish;
            end
            
            begin: timeout
                #20000; // 2000 cycles * 10ns = 20000ns
                $display("\n[ERROR] Simulation Timeout! GPIO Output not updated.");
                $display("Current GPIO Output: %d", gpio_out);
                $finish;
            end
        join
    end

endmodule
