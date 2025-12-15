// ============================================================================
// Testbench for Pipelined MIPS CPU
// Tests pipeline operation, hazards, forwarding, and various instruction types
// ============================================================================

module tb_pipelined_mips_top;

    // Clock and reset
    reg         clk;
    reg         rst;
    reg  [4:0]  ra3;
    wire [31:0] rd3;
    
    // Internal signals for monitoring
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] alu_out;
    wire [31:0] wd_dm;
    wire [31:0] rd_dm;
    wire        we_dm;
    
    // Cycle counter for analysis
    integer cycle_count;
    
    // Instantiate pipelined MIPS top module
    pipelined_mips_top DUT (
        .clk(clk),
        .rst(rst),
        .ra3(ra3)
    );
    
    // Access internal signals for debugging
    assign pc = DUT.pc;
    assign instr = DUT.instr;
    assign alu_out = DUT.data_addr;
    assign wd_dm = DUT.write_data;
    assign rd_dm = DUT.read_data;
    assign we_dm = DUT.mem_write;
    assign rd3 = DUT.rd3;
    
    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Cycle and Instruction counter
    integer instruction_count;
    initial begin
        cycle_count = 0;
        instruction_count = 0;
    end
    
    always @(posedge clk) begin
        if (!rst) cycle_count = cycle_count + 1;
        else cycle_count = 0;
        
        // Count retired instructions (valid in WB stage)
        if (!rst && DUT.cpu.dp.valid_W) begin
            instruction_count = instruction_count + 1;
        end
    end

    // Simulation control
    initial begin
        $dumpfile("pipelined_mips_tb.vcd");
        $dumpvars(0, tb_pipelined_mips_top);
        
        // Display headers
        $display("========================================");
        $display("Pipelined MIPS CPU Testbench");
        $display("========================================");
        $display("");
        $display("Time | Cycle | PC   | Instruction | ALU Out  | ID WE  | Desc | StallF/D FlushE/D | Val D E W");
        $display("-----|-------|------|-------------|----------|--------|------|-------------------|-----------");
        
        // Initialize
        rst = 1;
        ra3 = 5'h0;
        
        // Reset for 3 cycles
        #15;
        rst = 0;
        
        $display("");
        $display("=== Starting Pipeline Execution ===");
        $display("");
        
        // Run until timeout (safeguard)
        #5000;
        
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Monitor Pipeline including Stalls and Flushes
    // Sample on negedge to capture stable hazard signals generated during the cycle
    always @(negedge clk) begin
        if (!rst) begin
            $display("%4t | %5d | %04h | %08h    | %08h | %1b      | %s | %b/%b %b %b    | %b %b %b", 
                     $time, cycle_count, pc, instr, DUT.cpu.dp.alu_out_M, 
                     DUT.cpu.dp.we_dm_D, // Show ID stage WE to match instruction being decoded
                     decode_instruction(instr),
                     DUT.cpu.dp.stall_F, DUT.cpu.dp.stall_D, DUT.cpu.dp.flush_E, DUT.cpu.dp.flush_D,
                     DUT.cpu.dp.valid_D, DUT.cpu.dp.valid_E, DUT.cpu.dp.valid_W);
            
            // Debug Hazards inputs
            // Uses hierarchical path to hazard unit (dut.cpu.dp.hdu)
            // Comment out if hdu instance name differs
            // $display("Hazards: lwstall=%b BranchD=%b JumpD=%b JumpRegD=%b StallF=%b FlushD=%b",
            //          DUT.cpu.dp.hdu.lwstall, 
            //          DUT.cpu.dp.pc_src_D, 
            //          DUT.cpu.dp.jump_D, 
            //          DUT.cpu.dp.jump_reg_D, 
            //          DUT.cpu.dp.stall_F, 
            //          DUT.cpu.dp.flush_D);
                     
            // Assertion for SLT memory write safety
            if (DUT.cpu.dp.opcode_D == 6'b000000 && DUT.cpu.dp.funct_D == 6'b101010) begin // SLT
                if (DUT.cpu.dp.we_dm_D == 1) $display("ERROR: SLT has MemWrite set!");
            end
        end
    end

    // End of simulation detection
    always @(posedge clk) begin
        if (!rst && pc == 32'h58) begin // End of program address
            $display("Program finished at cycle %d", cycle_count);
            $display("========================================");
            $display("Pipeline Statistics");
            $display("Total cycles: %d", cycle_count);
            $display("Total Retired Instructions: %d", instruction_count);
            $display("Estimated CPI: %f", $itor(cycle_count)/$itor(instruction_count));
            $display("========================================");
            $display("Final Register States:");
            
            // Check specific registers as requested
            $display("Register values:");
            // We use the register file directly or the test port
            // Test port ra3/rd3 usage:
            ra3 = 2; #1; $display("  $2  = 0x%08h (%0d)", rd3, rd3);
            ra3 = 4; #1; $display("  $4  = 0x%08h (%0d)", rd3, rd3);
            ra3 = 8; #1; $display("  $8  = 0x%08h (%0d)", rd3, rd3);
            ra3 = 16; #1; $display("  $16 = 0x%08h (%0d)", rd3, rd3);
            ra3 = 29; #1; $display("  $29 = 0x%08h (%0d)", rd3, rd3);
            ra3 = 31; #1; $display("  $31 = 0x%08h (%0d)", rd3, rd3);
            
            $finish;
        end
    end

    // Function to decode instruction for display
    function [8*7:1] decode_instruction;
        input [31:0] inst;
        reg [5:0] opcode;
        reg [5:0] funct;
        begin
            opcode = inst[31:26];
            funct = inst[5:0];
            
            case (opcode)
                6'b000000: begin // R-type
                    case (funct)
                        6'b100000: decode_instruction = "ADD";
                        6'b100010: decode_instruction = "SUB";
                        6'b100100: decode_instruction = "AND";
                        6'b100101: decode_instruction = "OR";
                        6'b101010: decode_instruction = "SLT";
                        6'b000000: decode_instruction = "SLL";
                        6'b000010: decode_instruction = "SRL";
                        6'b001000: decode_instruction = "JR";
                        6'b011001: decode_instruction = "MULTU";
                        6'b010000: decode_instruction = "MFHI";
                        6'b010010: decode_instruction = "MFLO";
                        default:   decode_instruction = "R-type";
                    endcase
                end
                6'b001000: decode_instruction = "ADDI";
                6'b100011: decode_instruction = "LW";
                6'b101011: decode_instruction = "SW";
                6'b000100: decode_instruction = "BEQ";
                6'b000010: decode_instruction = "J";
                6'b000011: decode_instruction = "JAL";
                default:   decode_instruction = "UNKNOWN";
            endcase
        end
    endfunction

endmodule
