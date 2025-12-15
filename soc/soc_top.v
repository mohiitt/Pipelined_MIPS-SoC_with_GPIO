

module soc_top (

    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_memRead,
    input  wire        cpu_memWrite,
    output wire [31:0] cpu_rdata,

    input  wire [31:0] gpio_in_pins,
    output wire [31:0] gpio_out_pins
);

    wire cs_data_mem;
    wire cs_gpio;
    wire cs_fact;

    wire [31:0] rdata_data_mem;
    wire [31:0] rdata_gpio;
    wire [31:0] rdata_fact;

    wire [31:0] dmem_addr_word;
    wire [5:0]  dmem_addr_6bit;

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

    assign dmem_addr_6bit = cpu_addr[7:2];

    dmem u_data_mem (
        .clk    (clk),
        .rst    (rst),
        .we     (cs_data_mem & cpu_memWrite),
        .a      (dmem_addr_6bit),
        .wd     (cpu_wdata),
        .rd     (rdata_data_mem)
    );

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