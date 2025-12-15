// Factorial Accelerator Design
module factorial_accelerator #(
    parameter DATA_WIDTH = 32,
    parameter CNT_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    go,
    input  wire [CNT_WIDTH-1:0]    n,
    output reg  [DATA_WIDTH-1:0]   result,
    output reg                     done,
    output reg                     error
);

    // Internal signals
    wire [CNT_WIDTH-1:0]   cnt_out;
    wire [DATA_WIDTH-1:0]  reg_out;
    wire [DATA_WIDTH-1:0]  mul_out;
    wire [DATA_WIDTH-1:0]  mux_1_out;
    wire                   is_n_gt_12;
    wire                   is_n_gt_1;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam INIT = 2'b01;
    localparam CALC = 2'b10;
    localparam DONE = 2'b11;
    
    reg [1:0] state, next_state;
    
    // Control signals
    reg load_cnt;
    reg en_cnt;
    reg load_reg;
    reg sel_mux_1;    // 0: select 1, 1: select mul_out
    reg sel_mux_2;    // 0: select 0 (error), 1: select reg_out
    // Down Counter (CNT)
    reg [CNT_WIDTH-1:0] counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            counter <= 0;
        else if (load_cnt)
            counter <= n;
        else if (en_cnt && counter > 1)
            counter <= counter - 1;
    end
    
    assign cnt_out = counter;
    
    // Data Register (REG)
    reg [DATA_WIDTH-1:0] product_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            product_reg <= 0;
        else if (load_reg)
            product_reg <= mux_1_out;
    end
    
    assign reg_out = product_reg;
    
    // Comparators with GT output (CMP)
    assign is_n_gt_12 = (n > 12) ? 1'b1 : 1'b0;
    assign is_n_gt_1 = (cnt_out > 1) ? 1'b1 : 1'b0;
    
    // Combinational Multiplier (MUL)
    assign mul_out = reg_out * cnt_out;
    
    // MUX_1 (selects between 1 and mul_out)
    assign mux_1_out = sel_mux_1 ? mul_out : 32'd1;
    
    // MUX_2 (selects between 0 and reg_out)
    wire [DATA_WIDTH-1:0] mux_2_out;
    assign mux_2_out = sel_mux_2 ? mux_1_out : 32'd0;
    // State machine - sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // State machine - combinational logic
    always @(*) begin
        // Default values
        next_state = state;
        load_cnt = 1'b0;
        en_cnt = 1'b0;
        load_reg = 1'b0;
        sel_mux_1 = 1'b0;
        sel_mux_2 = 1'b1;
        done = 1'b0;
        error = 1'b0;
        
        case (state)
            IDLE: begin
                if (go) begin
                    if (is_n_gt_12) begin
                        next_state = DONE;
                        error = 1'b1;
                        sel_mux_2 = 1'b0; // Select 0 for error
                        load_reg = 1'b1;  // Update result register
                    end else if (n == 0 || n == 1) begin
                        next_state = DONE;
                        load_reg = 1'b1;
                        sel_mux_1 = 1'b0; // Load 1 into register
                    end else begin
                        next_state = INIT;
                    end
                end
            end
            
            INIT: begin
                load_cnt = 1'b1;  // Load n into counter
                load_reg = 1'b1;  // Load 1 into register
                sel_mux_1 = 1'b0; // Select 1
                next_state = CALC;
            end
            
            CALC: begin
                if (is_n_gt_1) begin
                    load_reg = 1'b1;  // Load new product
                    sel_mux_1 = 1'b1; // Select mul_out
                    en_cnt = 1'b1;    // Decrement counter
                    next_state = CALC; // Stay in CALC
                end else begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                done = 1'b1;
                if (!go)
                    next_state = IDLE;
            end
        endcase
    end
    
    // Output assignment
    always @(posedge clk or posedge reset) begin
        if (reset)
            result <= 0;
        else if (load_reg)
            result <= mux_2_out;
    end

endmodule