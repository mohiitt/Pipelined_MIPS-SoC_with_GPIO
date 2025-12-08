module dmem (
    input  wire        clk,
    input  wire        we,
    input  wire [5:0]  a,
    input  wire [31:0] wd,
    output wire [31:0] rd,
    input  wire        rst
);
    reg [31:0] ram [0:63];
    integer n;
    
    initial begin
        for (n = 0; n < 64; n = n + 1) 
            ram[n] = 32'hFFFFFFFF;  
    end
    
    always @ (posedge clk, posedge rst) begin
        if (rst) 
            for (n = 0; n < 64; n = n + 1) 
                ram[n] = 32'hFFFFFFFF; 
        else if (we) 
            ram[a] <= wd;
    end
 assign rd = ram[a];
endmodule

