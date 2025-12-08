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
    integer instruction_count;
    
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
    
    // Simulation control
    initial begin
        $dumpfile("pipelined_mips_tb.vcd");
        $dumpvars(0, tb_pipelined_mips_top);
        
        // Display headers
        $display("========================================");
        $display("Pipelined MIPS CPU Testbench");
        $display("========================================");
        $display("");
        $display("Time | Cycle | PC   | Instruction | ALU Out  | Mem WE | Description");
        $display("-----|-------|------|-------------|----------|--------|------------------");
    end
    
    // Monitor pipeline operation
    always @(posedge clk) begin
        if (!rst) begin
            $display("%4t | %5d | %04h | %08h    | %08h | %1b      | %s", 
                     $time, cycle_count, pc, instr, alu_out, we_dm, 
                     decode_instruction(instr));
        end
    end
    
    // Cycle counter
    initial begin
        cycle_count = 0;
        instruction_count = 0;
    end
    
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
        end else begin
            cycle_count = 0;
        end
    end
    
    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        ra3 = 5'h0;
        
        // Reset for 3 cycles
        #15;
        rst = 0;
        
        $display("");
        $display("=== Starting Pipeline Execution ===");
        $display("");
        
        // Run for sufficient cycles to complete program
        // Adjust this based on your program length
        #500;
        
        $display("");
        $display("=== Pipeline Statistics ===");
        $display("Total cycles: %d", cycle_count);
        $display("CPI: %f", cycle_count / 20.0); // Assuming ~20 instructions
        $display("");
        
        // Test register file contents
        $display("=== Register File Contents ===");
        test_registers();
        
        $display("");
        $display("========================================");
        $display("Testbench Complete");
        $display("========================================");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Task to read and display register values
    task test_registers;
        integer i;
        begin
            $display("Register values:");
            for (i = 0; i < 32; i = i + 1) begin
                ra3 = i;
                #1;
                if (rd3 !== 32'hxxxxxxxx && rd3 !== 0)
                    $display("  $%0d = 0x%08h (%0d)", i, rd3, rd3);
            end
            ra3 = 0;
        end
    endtask
    
    // Function to decode instruction for display
    function [200*8:1] decode_instruction;
        input [31:0] inst;
        reg [5:0] opcode;
        reg [5:0] funct;
        reg [4:0] rs, rt, rd;
        begin
            opcode = inst[31:26];
            funct = inst[5:0];
            rs = inst[25:21];
            rt = inst[20:16];
            rd = inst[15:11];
            
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
