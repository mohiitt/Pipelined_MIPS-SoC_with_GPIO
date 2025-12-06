module gpio (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        memRead,
    input  wire        memWrite,

    // GPIO external interface
    input  wire [31:0] gpio_in_pins,
    output reg  [31:0] gpio_out_pins
);

    // Memory-mapped addresses (within 0x00001000 - 0x00001FFF range)
    localparam GPIO_IN_ADDR  = 32'h00001000;  
    localparam GPIO_OUT_ADDR = 32'h00001004;

    // Write-side register (OUT)
    reg [31:0] gpio_out_reg;

    //-------------------------------------------
    // Sequential logic (writes + reset)
    //-------------------------------------------
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            gpio_out_reg  <= 32'h00000000;
            gpio_out_pins <= 32'h00000000;
        end 
        else begin
            if (memWrite) begin
                case (addr)
                    GPIO_OUT_ADDR: begin
                        gpio_out_reg  <= wdata;
                        gpio_out_pins <= wdata;
                    end
                    // GPIO_IN is read-only → ignore writes
                endcase
            end
        end
    end

    //-------------------------------------------
    // Combinational read-mux
    //-------------------------------------------
    always @(*) begin
        if (memRead) begin
            case (addr)
                GPIO_IN_ADDR:  rdata = gpio_in_pins;  // direct read of external pins
                GPIO_OUT_ADDR: rdata = gpio_out_reg;  // allow reading for debug
                default:       rdata = 32'h00000000;
            endcase
        end
        else begin
            rdata = 32'h00000000;
        end
    end

endmodule
