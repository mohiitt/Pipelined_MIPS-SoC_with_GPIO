

module addr_decoder (

    input  wire [31:0] addr,
    input  wire        memRead,
    input  wire        memWrite,

    input  wire [31:0] rdata_data_mem,
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_fact,

    output wire        cs_data_mem,
    output wire        cs_gpio,
    output wire        cs_fact,

    output reg  [31:0] rdata_out
);

    localparam ADDR_DATA_MEM_BASE = 32'h00000000;
    localparam ADDR_DATA_MEM_END  = 32'h00000FFF;

    localparam ADDR_GPIO_BASE     = 32'h00001000;
    localparam ADDR_GPIO_END      = 32'h00001FFF;

    localparam ADDR_FACT_BASE     = 32'h00002000;
    localparam ADDR_FACT_END      = 32'h00002FFF;

    wire in_data_mem_range;
    wire in_gpio_range;
    wire in_fact_range;

    assign in_data_mem_range = (addr >= ADDR_DATA_MEM_BASE) && (addr <= ADDR_DATA_MEM_END);
    assign in_gpio_range     = (addr >= ADDR_GPIO_BASE)     && (addr <= ADDR_GPIO_END);
    assign in_fact_range     = (addr >= ADDR_FACT_BASE)     && (addr <= ADDR_FACT_END);

    assign cs_data_mem = in_data_mem_range && (memRead || memWrite);
    assign cs_gpio     = in_gpio_range     && (memRead || memWrite);
    assign cs_fact     = in_fact_range     && (memRead || memWrite);

    always @(*) begin

        rdata_out = 32'h00000000;

        if (in_data_mem_range) begin
            rdata_out = rdata_data_mem;
        end
        else if (in_gpio_range) begin
            rdata_out = rdata_gpio;
        end
        else if (in_fact_range) begin
            rdata_out = rdata_fact;
        end

    end

endmodule