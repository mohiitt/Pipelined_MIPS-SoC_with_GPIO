/*
 * SoC Top-Level Module
 * 
 * This module integrates all memory-mapped peripherals and the address decoder,
 * providing a unified memory interface for CPU integration.
 * 
 * The CPU interface is provided as placeholder ports. No CPU is instantiated here.
 * 
 * Integrated Components:
 * - Data Memory (dmem)
 * - GPIO peripheral
 * - Factorial Accelerator wrapper
 * - Address Decoder
 * 
 * Address Map:
 * 0x00000000 - 0x00000FFF: Data Memory
 * 0x00001000 - 0x00001FFF: GPIO
 * 0x00002000 - 0x00002FFF: Factorial Accelerator
 */

module soc_top (
    // System signals
    input  wire        clk,
    input  wire        rst,
    
    // CPU interface (placeholder - no CPU instantiated)
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_memRead,
    input  wire        cpu_memWrite,
    output wire [31:0] cpu_rdata,
    
    // GPIO external interface
    input  wire [31:0] gpio_in_pins,
    output wire [31:0] gpio_out_pins
);

    // ========================================
    // Internal Signals
    // ========================================
    
    // Chip select signals from address decoder
    wire cs_data_mem;
    wire cs_gpio;
    wire cs_fact;
    
    // Read data signals from each peripheral
    wire [31:0] rdata_data_mem;
    wire [31:0] rdata_gpio;
    wire [31:0] rdata_fact;
    
    // Data memory specific signals
    wire [31:0] dmem_addr_word;
    wire [5:0]  dmem_addr_6bit;
    
    // ========================================
    // Address Decoder
    // ========================================
    
    addr_decoder u_addr_decoder (
        .addr           (cpu_addr),
        .memRead        (cpu_memRead),
        .memWrite       (cpu_memWrite),
        .rdata_data_mem (rdata_data_mem),
        .rdata_gpio     (rdata_gpio),
        .rdata_fact     (rdata_fact),
        .cs_data_mem    (cs_data_mem),
        .cs_gpio        (cs_gpio),
        .cs_fact        (cs_fact),
        .rdata_out      (cpu_rdata)
    );
    
    // ========================================
    // Data Memory (dmem)
    // ========================================
    // Note: dmem uses 6-bit word address (64 words = 256 bytes)
    // Extract bits [7:2] for word addressing
    
    assign dmem_addr_6bit = cpu_addr[7:2];
    
    dmem u_data_mem (
        .clk    (clk),
        .rst    (rst),
        .we     (cs_data_mem & cpu_memWrite),
        .a      (dmem_addr_6bit),
        .d      (cpu_wdata),
        .q      (rdata_data_mem)
    );
    
    // ========================================
    // GPIO Peripheral
    // ========================================
    
    gpio u_gpio (
        .clk          (clk),
        .rst          (rst),
        .addr         (cpu_addr),
        .wdata        (cpu_wdata),
        .rdata        (rdata_gpio),
        .memRead      (cs_gpio & cpu_memRead),
        .memWrite     (cs_gpio & cpu_memWrite),
        .gpio_in_pins (gpio_in_pins),
        .gpio_out_pins(gpio_out_pins)
    );
    
    // ========================================
    // Factorial Accelerator Wrapper
    // ========================================
    
    factorial_wrapper u_factorial_wrapper (
        .clk      (clk),
        .rst      (rst),
        .addr     (cpu_addr),
        .wdata    (cpu_wdata),
        .rdata    (rdata_fact),
        .memRead  (cs_fact & cpu_memRead),
        .memWrite (cs_fact & cpu_memWrite)
    );

endmodule