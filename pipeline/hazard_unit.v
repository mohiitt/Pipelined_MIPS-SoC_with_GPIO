// ============================================================================
// Hazard Detection Unit for Pipelined MIPS
// Detects: Load-Use hazards, JR hazards, Branch hazards
// Generates: Stall signal and Flush signal
// ============================================================================

// Hazard detection and Forwarding Unit
// Combined per User Request
module hazard_unit(
    // Inputs from pipeline stages
    input [4:0] RsD, RtD,           // Source registers in Decode
    input [4:0] RsE, RtE,           // Source registers in Execute  
    input [4:0] WriteRegE,          // Dest register in Execute
    input [4:0] WriteRegM,          // Dest register in Memory
    input [4:0] WriteRegW,          // Dest register in Writeback
    input RegWriteE, RegWriteM, RegWriteW,  // Write enable signals
    input MemToRegE, MemToRegM,     // Load instruction indicators
    input BranchD,                  // Branch in Decode
    input JumpD,                    // Jump in Decode (J/JAL)
    input JumpRegD,                 // Jump register in Decode (JR)
    input [5:0] OpcodeD, FunctD,    // For MULTU detection
    input clk, rst,                 // For multi-cycle stall

    // Outputs to control pipeline
    output reg StallF,              // Stall Fetch stage
    output reg StallD,              // Stall Decode stage
    output reg FlushE,              // Flush Execute stage
    output reg FlushD,              // Flush Decode stage
    output reg [1:0] ForwardAE,     // Forward path for RsE
    output reg [1:0] ForwardBE      // Forward path for RtE
);

// LOAD-USE HAZARD DETECTION
// If instruction in EX is a load, and instruction in ID uses that register
wire lwstall;
assign lwstall = MemToRegE && 
                 ((WriteRegE == RsD) || (WriteRegE == RtD)) &&
                 (WriteRegE != 0);  // Don't stall for $0

// MULTU STALL LOGIC (Multi-cycle operation simulation)
// Stall in Decode stage for 4 cycles to simulate multiplication latency
reg [1:0] mult_cnt;
wire is_mult_D = (OpcodeD == 6'b000000 && FunctD == 6'b011001); // MULTU
wire mult_stall = is_mult_D && (mult_cnt < 3);

always @(posedge clk or posedge rst) begin
    if (rst) mult_cnt <= 0;
    else if (mult_stall) mult_cnt <= mult_cnt + 1;
    else mult_cnt <= 0;
end

// BRANCH/JUMP FLUSH LOGIC
// When branch/jump detected in Decode, must flush the Execute stage
wire control_flush;
assign control_flush = (BranchD || JumpD || JumpRegD);

// COMBINE STALL/FLUSH LOGIC
always @(*) begin
    // Default: no stalls or flushes
    StallF = 0;
    StallD = 0;
    FlushE = 0;
    FlushD = 0;
    
    // Load-use hazard: stall IF and ID, flush EX
    if (lwstall) begin
        StallF = 1;
        StallD = 1;
        FlushE = 1;  // Insert bubble in Execute stage
    end
    
    // MULTU Stall: stall everything
    if (mult_stall) begin
        StallF = 1;
        StallD = 1;
        FlushE = 1; // Insert bubble
    end
    
    // Control hazard: flush Decode stage after delay slot
    if (control_flush && !StallD) begin // Only flush if not stalled
        FlushD = 1;  // Flush the instruction after branch/jump
    end
end

// FORWARDING LOGIC (to avoid unnecessary stalls)
always @(*) begin
    // Forward from Memory stage
    if (RegWriteM && (WriteRegM != 0) && (WriteRegM == RsE))
        ForwardAE = 2'b10;  // Forward from Memory
    // Forward from Writeback stage
    else if (RegWriteW && (WriteRegW != 0) && (WriteRegW == RsE))
        ForwardAE = 2'b01;  // Forward from Writeback
    else
        ForwardAE = 2'b00;  // No forwarding
        
    // Same for RtE
    if (RegWriteM && (WriteRegM != 0) && (WriteRegM == RtE))
        ForwardBE = 2'b10;
    else if (RegWriteW && (WriteRegW != 0) && (WriteRegW == RtE))
        ForwardBE = 2'b01;
    else
        ForwardBE = 2'b00;
end

endmodule
