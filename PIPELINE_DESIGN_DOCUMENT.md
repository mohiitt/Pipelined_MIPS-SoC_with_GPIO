# Pipelined MIPS CPU - Complete Transformation Guide

## Overview
This document describes the transformation of a single-cycle MIPS CPU into a fully functional 5-stage pipelined processor with hazard detection, data forwarding, and control hazard handling.

---

## Pipeline Stages

### IF (Instruction Fetch)
- **Location:** PC register, instruction memory
- **Operations:**
  - Fetch instruction from IMEM using PC
  - Calculate PC+4
  - Select next PC (normal, branch, jump, or jr)
- **Outputs:** `instr_F`, `pc_plus4_F`

### ID (Instruction Decode)
- **Location:** After IF/ID pipeline register
- **Operations:**
  - Decode instruction fields (opcode, rs, rt, rd, shamt, imm)
  - Generate all control signals
  - Read register file
  - Sign-extend immediate
  - Calculate branch target address
  - Perform branch comparison (early resolution)
  - Detect hazards
- **Outputs:** Control signals, `rd1_D`, `rd2_D`, `sext_imm_D`, branch/jump decisions

### EX (Execute)
- **Location:** After ID/EX pipeline register
- **Operations:**
  - Forward data from later stages
  - Perform ALU operation
  - Execute multiplication
  - Select write register (rt vs rd)
- **Outputs:** `alu_out_E`, `mult_product_E`, `write_reg_E`

### MEM (Memory)
- **Location:** After EX/MEM pipeline register
- **Operations:**
  - Access data memory (read/write)
  - Write HILO register (for MULTU)
- **Outputs:** `rd_dm_M`, `hi_out_M`, `lo_out_M`

### WB (Writeback)
- **Location:** After MEM/WB pipeline register
- **Operations:**
  - Select between ALU result, memory data, HI, or LO
  - Handle JAL (write PC+4 to $ra)
  - Write result to register file
- **Outputs:** `result_W` written to register file

---

## Pipeline Register Specifications

### IF/ID Register (`if_id_reg.v`)
```verilog
Inputs:
  - enable  : Stall control (1=update, 0=hold)
  - flush   : Clear to NOP on control hazard
  
Fields:
  - instr_F    [31:0]  → instr_D
  - pc_plus4_F [31:0]  → pc_plus4_D
```

### ID/EX Register (`id_ex_reg.v`)
```verilog
Inputs:
  - flush   : Insert bubble on hazard

Control Signals:
  - reg_dst_D, alu_src_D, alu_ctrl_D[3:0]
  - we_dm_D, dm2reg_D, we_reg_D
  - hilo_wd_D, hilo_mux_ctrl_D[1:0]

Data Fields:
  - rd1_D[31:0], rd2_D[31:0]       : Register values
  - rs_D[4:0], rt_D[4:0], rd_D[4:0] : Register addresses
  - sext_imm_D[31:0]                : Immediate value
  - shamt_D[4:0]                    : Shift amount
  - pc_plus4_D[31:0]                : For JAL
```

### EX/MEM Register (`ex_mem_reg.v`)
```verilog
Control Signals:
  - we_dm_E, dm2reg_E, we_reg_E
  - hilo_wd_E, hilo_mux_ctrl_E[1:0]

Data Fields:
  - alu_out_E[31:0]       : ALU result
  - wd_dm_E[31:0]         : Memory write data
  - write_reg_E[4:0]      : Destination register
  - pc_plus4_E[31:0]      : For JAL
  - mult_product_E[63:0]  : Multiplier output
```

### MEM/WB Register (`mem_wb_reg.v`)
```verilog
Control Signals:
  - dm2reg_W, we_reg_W
  - hilo_mux_ctrl_W[1:0]

Data Fields:
  - alu_out_W[31:0]   : ALU result
  - rd_dm_W[31:0]     : Memory read data
  - write_reg_W[4:0]  : Destination register
  - pc_plus4_W[31:0]  : For JAL
  - hi_out_W[31:0]    : HI register value
  - lo_out_W[31:0]    : LO register value
```

---

## Hazard Detection & Resolution

### 1. Data Hazards

#### Load-Use Hazard
**Problem:** Instruction in EX is a load (LW), and instruction in ID needs the loaded value.

**Detection:**
```verilog
if (dm2reg_E && ((rt_E == rs_D) || (rt_E == rt_D)))
    stall = 1
```

**Resolution:**
- Stall PC (disable PC update)
- Stall IF/ID (hold instruction in ID)
- Insert bubble in ID/EX (clear control signals)

#### RAW Hazard (Read After Write)
**Problem:** Instruction in EX/MEM or MEM/WB writes a register that instruction in EX needs.

**Resolution:** Data forwarding (see Forwarding Unit below)

### 2. Control Hazards

#### Branch Hazard
**Early Resolution Strategy:** Branch decision made in ID stage
- Compare registers in ID
- Calculate branch target in ID
- Flush IF/ID if branch taken

**Problem:** Branch depends on registers being written by earlier instructions

**Detection:**
```verilog
if (branch_D && 
    ((we_reg_E && (write_reg_E == rs_D || write_reg_E == rt_D)) ||
     (we_reg_M && (write_reg_M == rs_D || write_reg_M == rt_D))))
    stall = 1
```

**Resolution:** Stall until branch operands are available

#### Jump/JAL Hazard
**Resolution:** Flush IF/ID when jump/jal detected (kill fetched instruction)

#### JR Hazard
**Problem:** JR reads rs in ID for jump target, but rs might be written by earlier instruction

**Detection:**
```verilog
if (jump_reg_D && 
    ((we_reg_E && write_reg_E == rs_D) ||
     (we_reg_M && write_reg_M == rs_D)))
    stall = 1
```

**Resolution:** Stall until rs is available

### 3. Forwarding Unit (`forwarding_unit.v`)

**Purpose:** Forward ALU results from later stages to EX stage to avoid stalls

**ForwardA (ALU input A):**
```
if (EX/MEM.we_reg && EX/MEM.write_reg != 0 && EX/MEM.write_reg == rs_E)
    ForwardA = 2'b10  // Forward from EX/MEM
else if (MEM/WB.we_reg && MEM/WB.write_reg != 0 && MEM/WB.write_reg == rs_E)
    ForwardA = 2'b01  // Forward from MEM/WB
else
    ForwardA = 2'b00  // Use ID/EX value
```

**ForwardB (ALU input B):**
```
if (EX/MEM.we_reg && EX/MEM.write_reg != 0 && EX/MEM.write_reg == rt_E)
    ForwardB = 2'b10  // Forward from EX/MEM
else if (MEM/WB.we_reg && MEM/WB.write_reg != 0 && MEM/WB.write_reg == rt_E)
    ForwardB = 2'b01  // Forward from MEM/WB
else
    ForwardB = 2'b00  // Use ID/EX value
```

**Forwarding Paths:**
- **EX/MEM → EX:** Forward `alu_out_M`
- **MEM/WB → EX:** Forward `result_W` (final writeback value)

---

## Control Signal Propagation

| Signal | Stage Generated | Stage Used | Pipeline Path |
|--------|----------------|------------|---------------|
| `reg_dst` | ID | EX | ID → ID/EX → EX |
| `alu_src` | ID | EX | ID → ID/EX → EX |
| `alu_ctrl[3:0]` | ID | EX | ID → ID/EX → EX |
| `we_dm` | ID | MEM | ID → ID/EX → EX/MEM → MEM |
| `dm2reg` | ID | WB | ID → ID/EX → EX/MEM → MEM/WB → WB |
| `we_reg` | ID | WB | ID → ID/EX → EX/MEM → MEM/WB → WB |
| `hilo_wd` | ID | MEM | ID → ID/EX → EX/MEM → MEM |
| `hilo_mux_ctrl[1:0]` | ID | WB | ID → ID/EX → EX/MEM → MEM/WB → WB |
| `branch` | ID | ID (immediate) | Used in ID, not propagated |
| `jump` | ID | ID (immediate) | Used in ID, not propagated |
| `jal` | ID | ID (immediate) | Used in ID, not propagated |
| `jump_reg` | ID | ID (immediate) | Used in ID, not propagated |

---

## PC Control Logic

### PC Source Selection (in IF stage, controlled by ID stage)

```verilog
pc_next = (jump_D)     ? jta_D :      // Jump target
          (pc_src_D)   ? bta_D :      // Branch target (branch taken)
          (jump_reg_D) ? rd1_D :      // JR target (rs value)
                         pc_plus4_F;   // Normal PC+4
```

### PC Stall Control
```verilog
PC.enable = ~stall_F
```

### Flush Control
```verilog
flush_IF/ID = (jump_D | jal_D | pc_src_D | jump_reg_D)
flush_ID/EX = flush_IF/ID | stall_condition
```

---

## Special Features

### HILO Register Support (MULTU/MFHI/MFLO)

**MULTU Execution:**
1. **EX Stage:** Multiplier computes product
2. **EX/MEM Register:** Product propagated to MEM stage
3. **MEM Stage:** HILO register written with 64-bit product
4. **WB Stage:** (no writeback to register file for MULTU)

**MFHI/MFLO Execution:**
1. **ID Stage:** Control signals generated with `hilo_mux_ctrl`
2. **EX Stage:** ALU operation is NOP
3. **MEM Stage:** HILO values read
4. **MEM/WB Register:** HI/LO values propagated
5. **WB Stage:** MUX selects HI or LO based on `hilo_mux_ctrl_W`

### JAL (Jump and Link)

**JAL Execution:**
1. **ID Stage:** 
   - Control unit sets `jal = 1`
   - Write register forced to $ra (reg 31)
   - Jump target calculated: `{pc_plus4_D[31:28], instr[25:0], 2'b00}`
2. **All Stages:** PC+4 propagates through pipeline
3. **WB Stage:** PC+4 written to $ra instead of ALU/memory result

### Shift Instructions (SLL, SRL)

- **Shift amount** extracted from instruction in ID stage
- Propagated through ID/EX to EX stage
- ALU uses `shamt` instead of lower 5 bits of register

---

## Module Hierarchy

```
pipelined_mips_top.v
├── imem.v (instruction memory)
├── pipelined_mips.v
│   └── pipelined_datapath.v
│       ├── dreg.v (PC register with enable)
│       ├── if_id_reg.v (IF/ID pipeline register)
│       ├── controlunit.v (control signal generation)
│       │   ├── maindec.v
│       │   └── auxdec.v
│       ├── regfile.v (register file)
│       ├── signext.v (sign extender)
│       ├── adder.v (PC+4, branch target)
│       ├── hazard_unit.v (hazard detection)
│       ├── id_ex_reg.v (ID/EX pipeline register)
│       ├── forwarding_unit.v (forwarding control)
│       ├── mux2.v (forwarding muxes, alu_src, etc.)
│       ├── alu.v (ALU)
│       ├── multiplier.v (MULTU)
│       ├── ex_mem_reg.v (EX/MEM pipeline register)
│       ├── hilo_reg.v (HILO register)
│       ├── mem_wb_reg.v (MEM/WB pipeline register)
│       └── mux2.v (writeback muxes)
└── dmem.v (data memory)
```

---

## Instruction Support Summary

### R-Type Instructions
- **ADD, SUB, AND, OR, SLT:** Standard ALU operations
- **SLL, SRL:** Shift operations using shamt field
- **JR:** Jump register (special PC control)
- **MULTU:** Multiply unsigned (writes HILO)
- **MFHI, MFLO:** Move from HILO registers

### I-Type Instructions
- **ADDI:** Add immediate
- **LW:** Load word (causes load-use hazard if dependent)
- **SW:** Store word
- **BEQ:** Branch if equal (early resolution in ID)

### J-Type Instructions
- **J:** Jump (PC control in ID)
- **JAL:** Jump and link (writes PC+4 to $ra)

---

## Pipeline Behavior Examples

### Example 1: RAW Hazard with Forwarding
```assembly
add $t0, $t1, $t2   # I1: Write $t0 in WB stage (cycle 5)
sub $t3, $t0, $t4   # I2: Read $t0 in EX stage (cycle 4)
```

**Timeline:**
```
Cycle:  1    2    3    4    5
I1:     IF   ID   EX   MEM  WB
I2:          IF   ID   EX   MEM
                       ↑
                    Forward from EX/MEM
```

**Resolution:** Forward `alu_out_M` (I1's result) to I2's EX stage via ForwardA

### Example 2: Load-Use Hazard with Stall
```assembly
lw  $t0, 0($t1)     # I1: Load $t0 (available after MEM, cycle 4)
add $t2, $t0, $t3   # I2: Needs $t0 in EX (cycle 3) - TOO EARLY!
```

**Timeline:**
```
Cycle:  1    2    3    4    5    6
I1:     IF   ID   EX   MEM  WB
I2:          IF   ID   ID   EX   MEM
                       ↑
                    Stall
```

**Resolution:** Stall I2 in ID for one cycle, then forward from MEM/WB

### Example 3: Branch with Flush
```assembly
beq $t0, $t1, target  # I1: Branch decision in ID (cycle 2)
add $t2, $t3, $t4     # I2: Fetched but should not execute
target: ...
```

**Timeline:**
```
Cycle:  1    2    3
I1:     IF   ID   EX
I2:     IF   FLUSH
target:      IF   ID
```

**Resolution:** Flush I2 from IF/ID when branch taken

### Example 4: JR Hazard with Stall
```assembly
add $ra, $t0, $t1   # I1: Write $ra in WB (cycle 5)
jr  $ra             # I2: Read $ra in ID (cycle 3) - TOO EARLY!
```

**Timeline:**
```
Cycle:  1    2    3    4    5    6
I1:     IF   ID   EX   MEM  WB
I2:          IF   ID   ID   ID   EX
                       ↑    ↑
                    Stall x2
```

**Resolution:** Stall I2 until $ra is available (wait for WB)

---

## Wiring Summary

### Critical Paths

**IF → ID:**
- `instr_F` → IF/ID → `instr_D`
- `pc_plus4_F` → IF/ID → `pc_plus4_D`

**ID → EX:**
- `rd1_D`, `rd2_D` → ID/EX → `rd1_E`, `rd2_E` → Forwarding mux → ALU
- Control signals → ID/EX → Control path through EX/MEM/WB

**EX → MEM:**
- `alu_out_E` → EX/MEM → `alu_out_M` → DMEM address
- `alu_pb_fwd` → EX/MEM → `wd_dm_M` → DMEM write data
- `mult_product_E` → EX/MEM → `mult_product_M` → HILO register

**MEM → WB:**
- `alu_out_M` → MEM/WB → `alu_out_W` → Result mux
- `rd_dm_M` → MEM/WB → `rd_dm_W` → Result mux
- `hi_out_M`, `lo_out_M` → MEM/WB → Result mux

**WB → ID (Register File):**
- `result_W` → Register file write data
- `we_reg_W` → Register file write enable
- `write_reg_W` → Register file write address

**Forwarding Paths:**
- `alu_out_M` → Forwarding mux in EX
- `result_W` → Forwarding mux in EX

---

## ASCII Block Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PIPELINED MIPS CPU                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│          │     │          │     │          │     │          │     │          │
│    IF    │────▶│    ID    │────▶│    EX    │────▶│   MEM    │────▶│    WB    │
│          │     │          │     │          │     │          │     │          │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
     │                │                 │                │                │
     │           ┌────┴────┐       ┌────┴────┐     ┌────┴────┐      ┌────┴────┐
     │           │ IF/ID   │       │ ID/EX   │     │ EX/MEM  │      │ MEM/WB  │
     │           │ Reg     │       │  Reg    │     │  Reg    │      │  Reg    │
     │           └─────────┘       └─────────┘     └─────────┘      └─────────┘
     │
  ┌──┴──┐
  │ PC  │◀────── PC Source Mux (branch/jump/jr/PC+4)
  └─────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ IF Stage:  PC, IMEM, PC+4                                                    │
│ ID Stage:  Decode, Control Unit, RegFile Read, Branch Compare, Hazard Detect│
│ EX Stage:  Forwarding Unit, ALU, Multiplier                                 │
│ MEM Stage: DMEM, HILO Write                                                 │
│ WB Stage:  Result Mux, RegFile Write                                        │
└─────────────────────────────────────────────────────────────────────────────┘

Forwarding Paths:
    ┌─────────────────────────────────────┐
    │         ┌───────────────────────┐   │
    │         │                       ↓   ↓
   EX ──────▶ MEM ──────▶ WB ──────▶ (Forwarding Mux in EX)

Hazard Detection:
    ID/EX, EX/MEM ──────▶ Hazard Unit ──────▶ Stall/Flush Signals

Control Flow:
    ID (branch/jump decision) ──────▶ PC Mux, Flush IF/ID
```

---

## Testing Recommendations

1. **Basic Functionality:** Test each instruction type individually
2. **RAW Hazards:** Test forwarding with back-to-back ALU instructions
3. **Load-Use Hazards:** Test LW followed by dependent instruction
4. **Control Hazards:** Test branches, jumps, and JR
5. **MULTU/MFHI/MFLO:** Verify correct HILO operation through pipeline
6. **JAL:** Verify $ra is written with correct PC+4
7. **Complex Programs:** Factorial, Fibonacci, sorting algorithms

---

## Performance Notes

- **Ideal CPI:** 1.0 (one instruction per cycle)
- **CPI with Hazards:** 
  - Load-use: +1 cycle stall per occurrence
  - Branch misprediction: +1 cycle per taken branch
  - JR: +2 cycles stall (depends on dependency distance)
- **Throughput:** 5x improvement over single-cycle (in ideal case)
- **Latency:** 5 cycles per instruction (vs 1 in single-cycle)

---

## File List

### Pipeline Infrastructure
- `pipeline/if_id_reg.v` - IF/ID pipeline register
- `pipeline/id_ex_reg.v` - ID/EX pipeline register
- `pipeline/ex_mem_reg.v` - EX/MEM pipeline register
- `pipeline/mem_wb_reg.v` - MEM/WB pipeline register
- `pipeline/hazard_unit.v` - Hazard detection unit
- `pipeline/forwarding_unit.v` - Data forwarding unit
- `pipeline/dreg.v` - D register with enable (for PC)

### Top-Level Modules
- `pipeline/pipelined_datapath.v` - Complete pipelined datapath
- `pipeline/pipelined_mips.v` - Pipelined CPU (datapath wrapper)
- `pipeline/pipelined_mips_top.v` - Complete system with memory

### Reused from Single-Cycle
- `control_unit/controlunit.v`
- `control_unit/maindec.v`
- `control_unit/auxdec.v`
- `datapath/alu.v`
- `datapath/regfile.v`
- `datapath/signext.v`
- `datapath/adder.v`
- `datapath/mux2.v`
- `datapath/multiplier.v`
- `datapath/hilo_reg.v`
- `memory/imem.v`
- `memory/dmem.v`

---

## Conclusion

This pipelined MIPS implementation maintains full compatibility with the single-cycle design while achieving significantly higher throughput. All instructions are supported, hazards are properly handled, and the design is modular and well-documented.
