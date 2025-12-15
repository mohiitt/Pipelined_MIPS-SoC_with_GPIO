// ============================================================================
// Integrated SoC System Top Level
// Connects Pipelined MIPS Processor to SoC (Data Memory + Peripherals)
// ============================================================================

module soc_system_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3,
    // GPIO Interface (External)
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out
);

    // ========================================
    // Internal Signals
    // ========================================
    
    // MIPS <-> IMEM
    wire [31:0] pc;
    wire [31:0] instr;
    
    // MIPS <-> SoC (Data Bus)
    wire [31:0] data_addr;
    wire [31:0] write_data;
    wire [31:0] read_data;
    wire        mem_write;
    wire        mem_read;
    wire [31:0] rd3; // Debug port for register file

    // ========================================
    // Instruction Memory (Standard Harvard)
    // ========================================
    imem instruction_memory (
        .a(pc[7:2]),           // Word-addressed
        .rd(instr)
    );

    // ========================================
    // Pipelined MIPS CPU
    // ========================================
    pipelined_mips cpu (
        .clk(clk),
        .rst(rst),
        .ra3(ra3),
        .instr(instr),
        .rd_dm(read_data),
        .we_dm(mem_write),
        .pc_current(pc),
        .alu_out(data_addr),
        .wd_dm(write_data),
        .mem_read_dm(mem_read),
        .rd3(rd3)
    );

    // ========================================
    // System-on-Chip (SoC) Top Level
    // ========================================
    soc_top u_soc (
        .clk(clk),
        .rst(rst),
        .cpu_addr(data_addr),
        .cpu_wdata(write_data),
        .cpu_memRead(mem_read),
        .cpu_memWrite(mem_write),
        .cpu_rdata(read_data),
        .gpio_in_pins(gpio_in),
        .gpio_out_pins(gpio_out)
    );

endmodule
