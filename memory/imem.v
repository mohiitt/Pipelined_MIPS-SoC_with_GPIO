module imem (
        input  wire [5:0]  a,
        output wire [31:0] rd
    );

    reg [31:0] rom [0:63];

    initial begin
        $readmemh ("memfile.dat", rom);
    end

    assign rd = rom[a];

endmodule
