# Step-by-Step Transformation Guide
## Converting Single-Cycle MIPS to Pipelined MIPS

This document provides detailed, block-by-block instructions for transforming the single-cycle CPU into a pipelined design.

---

## STEP 1: PC (Program Counter)

### Single-Cycle Implementation
```verilog
dreg pc_reg (.clk(clk), .rst(rst), .d(pc_next), .q(pc_current));
```

### Pipelined Transformation

**Changes Required:**
1. Add **enable** signal to PC register (for stalls)
2. PC is now in **IF stage**
3. PC control logic receives signals from **ID stage**

**New Implementation:**
```verilog
// In IF stage
dreg #(32) pc_reg (
    .clk(clk),
    .rst(rst),
    .en(~stall_F),      // NEW: Enable when not stalled
    .d(pc_next_F),
    .q(pc_F)
);
```

**PC Source Selection:**
```verilog
// PC mux controlled by ID stage signals
assign pc_next_F = (jump_D)     ? jta_D :      // Jump
                   (pc_src_D)   ? bta_D :      // Branch taken
                   (jump_reg_D) ? rd1_D :      // JR
                                  pc_plus4_F;   // Normal
```

**What moves to which stage:**
- PC register: **IF stage**
- PC+4 calculation: **IF stage**
- PC source selection: **IF stage** (controlled by **ID stage**)

**New signals:**
- `stall_F`: From hazard unit, disables PC update
- `pc_next_F`: Selected next PC value

**Hazards handled:**
- **Stall:** PC doesn't update when `stall_F = 1`

---

## STEP 2: Instruction Memory (IMEM)

### Single-Cycle Implementation
```verilog
// External to datapath
input wire [31:0] instr
```

### Pipelined Transformation

**Changes Required:**
1. IMEM read is in **IF stage**
2. Instruction must be latched in **IF/ID register**

**New Implementation:**
```verilog
// In IF stage (external)
imem instruction_memory (
    .a(pc_F[7:2]),
    .rd(instr_F)        // NEW: Renamed to instr_F
);

// Latched in IF/ID register
if_id_reg if_id (
    .instr_F(instr_F),  // Input from IMEM
    .instr_D(instr_D)   // Output to ID stage
);
```

**What moves to which stage:**
- IMEM access: **IF stage**
- Instruction decode: **ID stage** (after IF/ID register)

**Hazards handled:**
- **Flush:** IF/ID register cleared on branch/jump

---

## STEP 3: IF/ID Pipeline Register

### Single-Cycle Implementation
N/A (no pipeline registers in single-cycle)

### Pipelined Transformation

**New Module Required:** `if_id_reg.v`

**Functionality:**
- Latches instruction and PC+4 on clock edge
- Supports **enable** (for stalls) and **flush** (for control hazards)

**Implementation:**
```verilog
if_id_reg if_id (
    .clk(clk),
    .rst(rst),
    .enable(~stall_D),      // Stall control
    .flush(flush_D),        // Flush on branch/jump
    .instr_F(instr_F),      // From IF
    .pc_plus4_F(pc_plus4_F),
    .instr_D(instr_D),      // To ID
    .pc_plus4_D(pc_plus4_D)
);
```

**Flush conditions:**
```verilog
assign flush_D = (jump_D | jal_D | pc_src_D | jump_reg_D);
```

---

## STEP 4: Control Unit

### Single-Cycle Implementation
```verilog
controlunit cu (
    .opcode(instr[31:26]),
    .funct(instr[5:0]),
    .branch(branch),
    .jump(jump),
    // ... all control signals
);
```

### Pipelined Transformation

**Changes Required:**
1. Control unit operates in **ID stage**
2. Receives instruction from **IF/ID register**
3. Control signals must propagate through pipeline

**New Implementation:**
```verilog
// In ID stage
wire [5:0] opcode_D = instr_D[31:26];
wire [5:0] funct_D  = instr_D[5:0];

controlunit cu (
    .opcode(opcode_D),     // From IF/ID register
    .funct(funct_D),
    .branch(branch_D),     // Used immediately in ID
    .jump(jump_D),         // Used immediately in ID
    .jal(jal_D),           // Used immediately in ID
    .jump_reg(jump_reg_D), // Used immediately in ID
    .reg_dst(reg_dst_D),   // Propagated to EX
    .alu_src(alu_src_D),   // Propagated to EX
    .alu_ctrl(alu_ctrl_D), // Propagated to EX
    .we_dm(we_dm_D),       // Propagated to MEM
    .dm2reg(dm2reg_D),     // Propagated to WB
    .we_reg(we_reg_D),     // Propagated to WB
    // ...
);
```

**What moves to which stage:**
- Control signal generation: **ID stage**
- Immediate use (branch/jump): **ID stage**
- Delayed use (ALU, memory, writeback): Propagated through **ID/EX → EX/MEM → MEM/WB**

**New signals registered in ID/EX:**
- `reg_dst_D`, `alu_src_D`, `alu_ctrl_D`
- `we_dm_D`, `dm2reg_D`, `we_reg_D`
- `hilo_wd_D`, `hilo_mux_ctrl_D`

---

## STEP 5: Register File

### Single-Cycle Implementation
```verilog
regfile rf (
    .clk(clk),
    .we(we_reg),           // Write in same cycle
    .ra1(instr[25:21]),
    .ra2(instr[20:16]),
    .wa(rf_wa),
    .wd(wd_rf),
    .rd1(alu_pa),
    .rd2(wd_dm),
    .rst(rst)
);
```

### Pipelined Transformation

**Changes Required:**
1. Read in **ID stage**
2. Write in **WB stage**
3. Write data/address come from **MEM/WB register**

**New Implementation:**
```verilog
// In ID stage
regfile rf (
    .clk(clk),
    .we(we_reg_W),              // NEW: Write enable from WB stage
    .ra1(rs_D),                 // NEW: Read from IF/ID
    .ra2(rt_D),                 // NEW: Read from IF/ID
    .wa(final_write_reg_W),     // NEW: Write address from WB
    .wd(final_wd_W),            // NEW: Write data from WB
    .rd1(rd1_D),                // NEW: Output to ID/EX
    .rd2(rd2_D),                // NEW: Output to ID/EX
    .rst(rst)
);
```

**What moves to which stage:**
- Register read: **ID stage**
- Register write: **WB stage** (data from MEM/WB register)

**New signals:**
- `rd1_D`, `rd2_D`: Register values read in ID
- Must be latched in **ID/EX register**

**Hazards handled:**
- **Data forwarding:** If register being written is needed in EX, forward from EX/MEM or MEM/WB
- **Load-use stall:** If register being loaded is needed immediately

---

## STEP 6: Sign Extension

### Single-Cycle Implementation
```verilog
signext se (.a(instr[15:0]), .y(sext_imm));
```

### Pipelined Transformation

**Changes Required:**
1. Operates in **ID stage**
2. Output must be latched in **ID/EX register**

**New Implementation:**
```verilog
// In ID stage
wire [15:0] imm_D = instr_D[15:0];
wire [31:0] sext_imm_D;

signext se (
    .a(imm_D),
    .y(sext_imm_D)
);

// Latched in ID/EX
id_ex_reg id_ex (
    .sext_imm_D(sext_imm_D),
    .sext_imm_E(sext_imm_E),
    // ...
);
```

**What moves to which stage:**
- Sign extension: **ID stage**
- Extended immediate used: **EX stage** (for ALU, after ID/EX)

---

## STEP 7: Branch Target Calculation

### Single-Cycle Implementation
```verilog
assign ba = {sext_imm[29:0], 2'b00};
adder pc_plus_br (.a(pc_plus4), .b(ba), .y(bta));
```

### Pipelined Transformation

**Changes Required:**
1. Branch target calculated in **ID stage** (early)
2. Uses PC+4 from **IF/ID register**
3. Branch decision made in **ID stage**

**New Implementation:**
```verilog
// In ID stage
wire [31:0] ba_D = {sext_imm_D[29:0], 2'b00};
wire [31:0] bta_D;

adder branch_adder (
    .a(pc_plus4_D),    // From IF/ID register
    .b(ba_D),
    .y(bta_D)          // Branch target address
);

// Branch comparator
assign zero_D = (rd1_D == rd2_D);
assign pc_src_D = branch_D & zero_D;
```

**What moves to which stage:**
- Branch target calculation: **ID stage**
- Branch comparison: **ID stage**
- Branch decision: **ID stage** (used immediately for PC)

**Hazards handled:**
- **Branch hazard:** If operands not ready (being written by earlier instruction), stall
- **Flush:** If branch taken, flush IF/ID

---

## STEP 8: Jump Target Calculation

### Single-Cycle Implementation
```verilog
assign jta = {pc_plus4[31:28], instr[25:0], 2'b00};
```

### Pipelined Transformation

**Changes Required:**
1. Jump target calculated in **ID stage**
2. Uses PC+4 from **IF/ID register**

**New Implementation:**
```verilog
// In ID stage
assign jta_D = {pc_plus4_D[31:28], instr_D[25:0], 2'b00};
```

**What moves to which stage:**
- Jump target calculation: **ID stage**
- Jump decision: **ID stage** (used immediately for PC)

---

## STEP 9: Hazard Detection Unit

### Single-Cycle Implementation
N/A (no hazards in single-cycle)

### Pipelined Transformation

**New Module Required:** `hazard_unit.v`

**Functionality:**
1. Detect **load-use hazards**
2. Detect **JR hazards**
3. Detect **branch hazards**
4. Generate stall and flush signals

**Implementation:**
```verilog
hazard_unit hdu (
    .rs_D(rs_D),
    .rt_D(rt_D),
    .branch_D(branch_D),
    .jump_reg_D(jump_reg_D),
    .rt_E(rt_E),
    .write_reg_E(write_reg_E),
    .we_reg_E(we_reg_E),
    .dm2reg_E(dm2reg_E),
    .write_reg_M(write_reg_M),
    .we_reg_M(we_reg_M),
    .stall_F(stall_F),      // Stall PC
    .stall_D(stall_D),      // Stall IF/ID
    .flush_E(flush_E)       // Flush ID/EX
);
```

**Stall logic:**
```verilog
// When hazard detected:
// - Disable PC update (stall_F)
// - Hold IF/ID register (stall_D)
// - Insert bubble in ID/EX (flush_E)
```

---

## STEP 10: ID/EX Pipeline Register

### Single-Cycle Implementation
N/A

### Pipelined Transformation

**New Module Required:** `id_ex_reg.v`

**Functionality:**
- Latch all control signals
- Latch register values
- Latch register addresses (for forwarding)
- Latch immediate, shamt, PC+4
- Support flush (insert bubble)

**Implementation:**
```verilog
id_ex_reg id_ex (
    .clk(clk),
    .rst(rst),
    .flush(flush_E | flush_D),
    // Control signals
    .reg_dst_D(reg_dst_D),   .reg_dst_E(reg_dst_E),
    .alu_src_D(alu_src_D),   .alu_src_E(alu_src_E),
    // ... all control signals
    // Data
    .rd1_D(rd1_D),           .rd1_E(rd1_E),
    .rd2_D(rd2_D),           .rd2_E(rd2_E),
    .rs_D(rs_D),             .rs_E(rs_E),
    .rt_D(rt_D),             .rt_E(rt_E),
    .rd_D(rd_D),             .rd_E(rd_E),
    // ...
);
```

---

## STEP 11: Forwarding Unit

### Single-Cycle Implementation
N/A (no forwarding in single-cycle)

### Pipelined Transformation

**New Module Required:** `forwarding_unit.v`

**Functionality:**
- Compare source registers in EX with destination registers in MEM/WB
- Generate forwarding control for ALU inputs A and B

**Implementation:**
```verilog
forwarding_unit fwd (
    .rs_E(rs_E),
    .rt_E(rt_E),
    .write_reg_M(write_reg_M),
    .we_reg_M(we_reg_M),
    .write_reg_W(write_reg_W),
    .we_reg_W(we_reg_W),
    .forward_A(forward_A),    // 00=ID/EX, 01=MEM/WB, 10=EX/MEM
    .forward_B(forward_B)
);
```

**Forwarding muxes:**
```verilog
// Forward to ALU input A
assign alu_pa_fwd = (forward_A == 2'b10) ? alu_out_M :
                    (forward_A == 2'b01) ? result_W :
                    rd1_E;

// Forward to ALU input B
assign alu_pb_fwd = (forward_B == 2'b10) ? alu_out_M :
                    (forward_B == 2'b01) ? result_W :
                    rd2_E;
```

---

## STEP 12: ALU

### Single-Cycle Implementation
```verilog
mux2 #(32) alu_pb_mux (.sel(alu_src), .a(wd_dm), .b(sext_imm), .y(alu_pb));

alu alu0 (
    .op(alu_ctrl),
    .a(alu_pa),
    .b(alu_pb),
    .shamt(shamt),
    .zero(zero),
    .y(alu_y)
);
```

### Pipelined Transformation

**Changes Required:**
1. ALU operates in **EX stage**
2. Inputs come from **forwarding muxes**
3. Control signals come from **ID/EX register**

**New Implementation:**
```verilog
// In EX stage

// ALU input A (with forwarding)
assign alu_pa_fwd = (forward_A == 2'b10) ? alu_out_M :
                    (forward_A == 2'b01) ? result_W :
                    rd1_E;

// ALU input B (with forwarding, before alu_src mux)
assign alu_pb_fwd = (forward_B == 2'b10) ? alu_out_M :
                    (forward_B == 2'b01) ? result_W :
                    rd2_E;

// ALU source mux (immediate vs register)
mux2 #(32) alu_src_mux (
    .sel(alu_src_E),
    .a(alu_pb_fwd),
    .b(sext_imm_E),
    .y(alu_pb_E)
);

// ALU
alu alu0 (
    .op(alu_ctrl_E),
    .a(alu_pa_fwd),
    .b(alu_pb_E),
    .shamt(shamt_E),
    .zero(zero_E),
    .y(alu_out_E)
);
```

**What moves to which stage:**
- ALU operation: **EX stage**
- ALU inputs: From **ID/EX** or **forwarded** from later stages
- ALU result: Latched in **EX/MEM register**

**New mux changes:**
- **Forwarding muxes** added before alu_src mux
- Three inputs to forwarding mux: ID/EX, EX/MEM, MEM/WB

---

## STEP 13: Multiplier

### Single-Cycle Implementation
```verilog
multiplier mult (
    .a(alu_pa),
    .b(wd_dm),
    .product(mult_product)
);
```

### Pipelined Transformation

**Changes Required:**
1. Multiplier operates in **EX stage**
2. Inputs are **forwarded** values
3. Product latched in **EX/MEM register**

**New Implementation:**
```verilog
// In EX stage
multiplier mult (
    .a(alu_pa_fwd),       // Forwarded value
    .b(alu_pb_fwd),       // Forwarded value
    .product(mult_product_E)
);

// Latched in EX/MEM
ex_mem_reg ex_mem (
    .mult_product_E(mult_product_E),
    .mult_product_M(mult_product_M),
    // ...
);
```

**What moves to which stage:**
- Multiplication: **EX stage**
- Product latched: **EX/MEM register**
- Product written to HILO: **MEM stage**

---

## STEP 14: Write Register Selection

### Single-Cycle Implementation
```verilog
mux2 #(5) rf_wa_mux (.sel(reg_dst), .a(instr[20:16]), .b(instr[15:11]), .y(rf_wa_base));
assign rf_wa = (jal) ? 5'd31 : rf_wa_base;
```

### Pipelined Transformation

**Changes Required:**
1. Selection happens in **EX stage**
2. Uses register fields from **ID/EX register**
3. Result propagates to **WB stage**

**New Implementation:**
```verilog
// In EX stage
wire [4:0] write_reg_E;

mux2 #(5) write_reg_mux (
    .sel(reg_dst_E),
    .a(rt_E),           // I-type: rt
    .b(rd_E),           // R-type: rd
    .y(write_reg_E)
);

// For JAL: write_reg is already forced to 31 in ID stage
// (reg_dst mux would select rd, but JAL sets it differently)
```

**What moves to which stage:**
- Write register selection: **EX stage**
- Propagated through: **EX/MEM → MEM/WB → WB**

---

## STEP 15: EX/MEM Pipeline Register

### Single-Cycle Implementation
N/A

### Pipelined Transformation

**New Module Required:** `ex_mem_reg.v`

**Functionality:**
- Latch control signals (we_dm, dm2reg, we_reg, hilo_wd, hilo_mux_ctrl)
- Latch ALU result
- Latch memory write data
- Latch write register address
- Latch multiplier product
- Latch PC+4 (for JAL)

**Implementation:**
```verilog
ex_mem_reg ex_mem (
    .clk(clk),
    .rst(rst),
    // Control
    .we_dm_E(we_dm_E),         .we_dm_M(we_dm_M),
    .dm2reg_E(dm2reg_E),       .dm2reg_M(dm2reg_M),
    .we_reg_E(we_reg_E),       .we_reg_M(we_reg_M),
    // Data
    .alu_out_E(alu_out_E),     .alu_out_M(alu_out_M),
    .wd_dm_E(alu_pb_fwd),      .wd_dm_M(wd_dm_M),
    .write_reg_E(write_reg_E), .write_reg_M(write_reg_M),
    .mult_product_E(mult_product_E), .mult_product_M(mult_product_M),
    // ...
);
```

---

## STEP 16: Data Memory

### Single-Cycle Implementation
```verilog
// External
input wire [31:0] rd_dm
output wire we_dm
output wire [31:0] alu_out   // address
output wire [31:0] wd_dm     // write data
```

### Pipelined Transformation

**Changes Required:**
1. DMEM access in **MEM stage**
2. Address and write data come from **EX/MEM register**
3. Read data latched in **MEM/WB register**

**New Implementation:**
```verilog
// External (in top module)
dmem data_memory (
    .clk(clk),
    .we(we_dm_M),           // From EX/MEM
    .a(alu_out_M[7:2]),     // Address from EX/MEM
    .wd(wd_dm_M),           // Write data from EX/MEM
    .rd(rd_dm)              // To MEM/WB
);

// In datapath
// alu_out_M is the address
// wd_dm_M is the write data
// rd_dm is latched in MEM/WB as rd_dm_W
```

**What moves to which stage:**
- Memory access: **MEM stage**
- Address/write data: From **EX/MEM register**
- Read data: Latched in **MEM/WB register**

---

## STEP 17: HILO Register

### Single-Cycle Implementation
```verilog
hilo_reg hilo (
    .clk(clk),
    .rst(rst),
    .we(multu_we),
    .product(mult_product),
    .hi(hi_out),
    .lo(lo_out)
);
```

### Pipelined Transformation

**Changes Required:**
1. HILO written in **MEM stage**
2. Product comes from **EX/MEM register**
3. HILO values read in **MEM stage**, latched in **MEM/WB**

**New Implementation:**
```verilog
// In MEM stage
hilo_reg hilo (
    .clk(clk),
    .rst(rst),
    .we(hilo_wd_M),           // From EX/MEM
    .product(mult_product_M), // From EX/MEM
    .hi(hi_out_M),
    .lo(lo_out_M)
);

// Latched in MEM/WB
mem_wb_reg mem_wb (
    .hi_out_M(hi_out_M), .hi_out_W(hi_out_W),
    .lo_out_M(lo_out_M), .lo_out_W(lo_out_W),
    // ...
);
```

**What moves to which stage:**
- HILO write: **MEM stage**
- HILO read for MFHI/MFLO: **MEM stage** → latched in **MEM/WB** → used in **WB**

---

## STEP 18: MEM/WB Pipeline Register

### Single-Cycle Implementation
N/A

### Pipelined Transformation

**New Module Required:** `mem_wb_reg.v`

**Functionality:**
- Latch control signals (dm2reg, we_reg, hilo_mux_ctrl)
- Latch ALU result
- Latch memory read data
- Latch write register address
- Latch HI/LO values
- Latch PC+4 (for JAL)

**Implementation:**
```verilog
mem_wb_reg mem_wb (
    .clk(clk),
    .rst(rst),
    // Control
    .dm2reg_M(dm2reg_M),       .dm2reg_W(dm2reg_W),
    .we_reg_M(we_reg_M),       .we_reg_W(we_reg_W),
    .hilo_mux_ctrl_M(hilo_mux_ctrl_M), .hilo_mux_ctrl_W(hilo_mux_ctrl_W),
    // Data
    .alu_out_M(alu_out_M),     .alu_out_W(alu_out_W),
    .rd_dm_M(rd_dm),           .rd_dm_W(rd_dm_W),
    .write_reg_M(write_reg_M), .write_reg_W(write_reg_W),
    .hi_out_M(hi_out_M),       .hi_out_W(hi_out_W),
    .lo_out_M(lo_out_M),       .lo_out_W(lo_out_W),
    // ...
);
```

---

## STEP 19: Writeback Stage

### Single-Cycle Implementation
```verilog
// HILO mux
case (hilo_mux_ctrl)
    2'b01: alu_out_sel = hi_out;
    2'b10: alu_out_sel = lo_out;
    default: alu_out_sel = alu_y;
endcase

// Memory to register mux
mux2 #(32) rf_wd_mem_mux (.sel(dm2reg), .a(alu_out), .b(rd_dm), .y(alu_or_mem));

// JAL mux
assign wd_rf = (jal) ? pc_plus4 : alu_or_mem;
```

### Pipelined Transformation

**Changes Required:**
1. Writeback happens in **WB stage**
2. All inputs come from **MEM/WB register**
3. Output goes to **register file** in **ID stage**

**New Implementation:**
```verilog
// In WB stage

// HILO output mux
reg [31:0] alu_or_hilo_W;
always @(*) begin
    case (hilo_mux_ctrl_W)
        2'b01:   alu_or_hilo_W = hi_out_W;   // MFHI
        2'b10:   alu_or_hilo_W = lo_out_W;   // MFLO
        default: alu_or_hilo_W = alu_out_W;
    endcase
end

// Memory to register mux
wire [31:0] result_W;
mux2 #(32) mem_to_reg_mux (
    .sel(dm2reg_W),
    .a(alu_or_hilo_W),
    .b(rd_dm_W),
    .y(result_W)
);

// JAL detection and writeback
wire jal_W = (write_reg_W == 5'd31) && we_reg_W;
wire [31:0] final_wd_W = jal_W ? pc_plus4_W : result_W;
wire [4:0] final_write_reg_W = write_reg_W;

// These connect to register file in ID stage
```

**What moves to which stage:**
- HILO selection: **WB stage**
- Memory/ALU selection: **WB stage**
- JAL PC+4 selection: **WB stage**
- Register file write: **ID stage** (receives data from WB)

---

## STEP 20: JAL Handling

### Single-Cycle Implementation
```verilog
// In ID:
assign rf_wa = (jal) ? 5'd31 : rf_wa_base;
assign wd_rf = (jal) ? pc_plus4 : alu_or_mem;
```

### Pipelined Transformation

**Changes Required:**
1. JAL detected in **ID stage**
2. Write register forced to $ra (31) in **ID stage**
3. PC+4 propagated through **ID/EX → EX/MEM → MEM/WB**
4. Final writeback in **WB stage** selects PC+4 instead of ALU result

**New Implementation:**
```verilog
// In ID stage (simplified: control unit handles jal signal)
// When jal=1, reg_dst is set such that write_reg becomes 31

// PC+4 propagates through pipeline
// In each pipeline register:
id_ex_reg:   .pc_plus4_D → .pc_plus4_E
ex_mem_reg:  .pc_plus4_E → .pc_plus4_M
mem_wb_reg:  .pc_plus4_M → .pc_plus4_W

// In WB stage:
assign jal_W = (write_reg_W == 5'd31) && we_reg_W;
assign final_wd_W = jal_W ? pc_plus4_W : result_W;
```

**What moves to which stage:**
- JAL detection: **ID stage**
- $ra selection: **ID/EX stage**
- PC+4 value: Propagated through all stages
- Final mux: **WB stage**

---

## Summary of Stage Boundaries

| Component | Single-Cycle | Pipelined Stage | Pipeline Register Input | Pipeline Register Output |
|-----------|--------------|-----------------|------------------------|--------------------------|
| PC | Single stage | IF | - | IF/ID |
| IMEM | Single stage | IF | - | IF/ID |
| Decode | Single stage | ID | IF/ID | ID/EX |
| Control Unit | Single stage | ID | IF/ID | ID/EX |
| RegFile Read | Single stage | ID | IF/ID | ID/EX |
| Sign Extend | Single stage | ID | IF/ID | ID/EX |
| Branch Target | Single stage | ID | IF/ID | - |
| ALU | Single stage | EX | ID/EX | EX/MEM |
| Multiplier | Single stage | EX | ID/EX | EX/MEM |
| DMEM | Single stage | MEM | EX/MEM | MEM/WB |
| HILO Write | Single stage | MEM | EX/MEM | MEM/WB |
| Writeback Mux | Single stage | WB | MEM/WB | RegFile (ID) |

---

## Critical Design Decisions

1. **Branch Resolution:** Early (in ID) to minimize control hazard penalty
2. **Forwarding Priority:** EX/MEM has priority over MEM/WB
3. **Load-Use:** Must stall (cannot forward from MEM before data is available)
4. **JR Handling:** Stall if rs not ready (can't forward to ID easily)
5. **HILO Timing:** Written in MEM stage, read in WB stage (via MEM/WB)
6. **PC Stall:** Disable PC register update, not insert NOPs

---

## Testing Transformation Steps

After implementing each step, test:

1. **After IF/ID:** Verify instructions latch correctly
2. **After control unit:** Verify control signals propagate
3. **After ID/EX:** Verify data and control reach EX
4. **After forwarding:** Test back-to-back ALU instructions
5. **After hazard unit:** Test load-use hazard stalls
6. **After EX/MEM:** Verify memory access works
7. **After MEM/WB:** Verify writeback completes
8. **Full pipeline:** Run complete programs

---

## Common Pitfalls to Avoid

1. **Forgetting to latch signals:** Every signal crossing stage boundary must be in pipeline register
2. **Wrong stage for control:** Branch/jump decisions in ID, not IF
3. **Forwarding to wrong place:** Forward to EX stage inputs, not ID
4. **Stall vs Flush confusion:** Stall holds values, flush inserts bubble (zeros)
5. **JAL writeback:** Must propagate PC+4 through entire pipeline
6. **HILO timing:** Product must reach MEM stage before writing
7. **Register $0:** Don't forward from $0 (always zero)

---

This completes the step-by-step transformation guide!
