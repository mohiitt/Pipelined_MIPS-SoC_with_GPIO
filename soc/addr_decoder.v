/*
 * Address Decoder for Memory-Mapped SoC
 * 
 * This module decodes memory addresses and generates chip select signals
 * for different memory-mapped peripherals. It also multiplexes read data
 * from the selected module back to the CPU.
 * 
 * Address Map:
 * 0x00000000 - 0x00000FFF: Data Memory (4KB)
 * 0x00001000 - 0x00001FFF: GPIO (4KB)
 * 0x00002000 - 0x00002FFF: Factorial Accelerator (4KB)
 * 
 * Chip selects are one-hot active-high signals.
 */

module addr_decoder (
    // Address and control inputs
    input  wire [31:0] addr,
    input  wire        memRead,
    input  wire        memWrite,
    
    // Read data inputs from each module
    input  wire [31:0] rdata_data_mem,
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_fact,
    
    // Chip select outputs (one-hot, active-high)
    output wire        cs_data_mem,
    output wire        cs_gpio,
    output wire        cs_fact,
    
    // Multiplexed read data output
    output reg  [31:0] rdata_out
);

    // Address range parameters
    localparam ADDR_DATA_MEM_BASE = 32'h00000000;
    localparam ADDR_DATA_MEM_END  = 32'h00000FFF;
    
    localparam ADDR_GPIO_BASE     = 32'h00001000;
    localparam ADDR_GPIO_END      = 32'h00001FFF;
    
    localparam ADDR_FACT_BASE     = 32'h00002000;
    localparam ADDR_FACT_END      = 32'h00002FFF;
    
    // Address range detection wires
    wire in_data_mem_range;
    wire in_gpio_range;
    wire in_fact_range;
    
    // Address range comparisons
    assign in_data_mem_range = (addr >= ADDR_DATA_MEM_BASE) && (addr <= ADDR_DATA_MEM_END);
    assign in_gpio_range     = (addr >= ADDR_GPIO_BASE)     && (addr <= ADDR_GPIO_END);
    assign in_fact_range     = (addr >= ADDR_FACT_BASE)     && (addr <= ADDR_FACT_END);
    
    // Chip select generation (active when in range AND accessing memory)
    // Chip selects are active for both read and write operations
    assign cs_data_mem = in_data_mem_range && (memRead || memWrite);
    assign cs_gpio     = in_gpio_range     && (memRead || memWrite);
    assign cs_fact     = in_fact_range     && (memRead || memWrite);
    
    // Read data multiplexer
    // Select read data from the appropriate module based on address range
    always @(*) begin
        // Default: return zeros if no module selected
        rdata_out = 32'h00000000;
        
        // Priority-based selection (one-hot by design, so priority doesn't matter)
        if (in_data_mem_range) begin
            rdata_out = rdata_data_mem;
        end
        else if (in_gpio_range) begin
            rdata_out = rdata_gpio;
        end
        else if (in_fact_range) begin
            rdata_out = rdata_fact;
        end
        // else: default to zeros for undefined addresses
    end

endmodule