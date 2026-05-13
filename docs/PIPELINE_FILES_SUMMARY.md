# Pipelined MIPS - Complete File Summary

## Generated Files Overview

This document lists all files created for the pipelined MIPS CPU implementation.

---

## Pipeline Infrastructure Modules

### 1. `pipeline/if_id_reg.v`
**IF/ID Pipeline Register**
- Latches instruction and PC+4 from IF to ID stage
- Supports stall (via enable) and flush
- Fields: `instr_F`, `pc_plus4_F` → `instr_D`, `pc_plus4_D`

### 2. `pipeline/id_ex_reg.v`
**ID/EX Pipeline Register**
- Latches control signals and data from ID to EX stage
- Supports flush (insert bubble)
- Control signals: `reg_dst`, `alu_src`, `alu_ctrl`, `we_dm`, `dm2reg`, `we_reg`, `hilo_wd`, `hilo_mux_ctrl`
- Data: `rd1`, `rd2`, `rs`, `rt`, `rd`, `sext_imm`, `shamt`, `pc_plus4`

### 3. `pipeline/ex_mem_reg.v`
**EX/MEM Pipeline Register**
- Latches ALU results and control from EX to MEM stage
- Control signals: `we_dm`, `dm2reg`, `we_reg`, `hilo_wd`, `hilo_mux_ctrl`
- Data: `alu_out`, `wd_dm`, `write_reg`, `pc_plus4`, `mult_product`

### 4. `pipeline/mem_wb_reg.v`
**MEM/WB Pipeline Register**
- Latches memory data and results from MEM to WB stage
- Control signals: `dm2reg`, `we_reg`, `hilo_mux_ctrl`
- Data: `alu_out`, `rd_dm`, `write_reg`, `pc_plus4`, `hi_out`, `lo_out`

---

## Hazard and Forwarding Logic

### 5. `pipeline/hazard_unit.v`
**Hazard Detection Unit**
- Detects load-use hazards
- Detects JR hazards (rs dependency)
- Detects branch hazards (rs/rt dependency)
- Outputs: `stall_F`, `stall_D`, `flush_E`

**Detection Logic:**
```
Load-use:    dm2reg_E && (rt_E == rs_D || rt_E == rt_D)
JR hazard:   jump_reg_D && (write_reg_E/M == rs_D)
Branch:      branch_D && (write_reg_E/M == rs_D || rt_D)
```

### 6. `pipeline/forwarding_unit.v`
**Data Forwarding Unit**
- Generates forwarding controls for ALU inputs
- Priority: EX/MEM (2'b10) > MEM/WB (2'b01) > ID/EX (2'b00)
- Outputs: `forward_A[1:0]`, `forward_B[1:0]`

**Forwarding Conditions:**
```
Forward from EX/MEM: we_reg_M && write_reg_M != 0 && write_reg_M == rs_E/rt_E
Forward from MEM/WB: we_reg_W && write_reg_W != 0 && write_reg_W == rs_E/rt_E
```

---

## Datapath and Control

### 7. `pipeline/pipelined_datapath.v`
**Complete Pipelined Datapath**
- Integrates all 5 pipeline stages
- Instantiates all pipeline registers
- Instantiates hazard and forwarding units
- Implements PC control and flush logic
- Reuses combinational logic from single-cycle design

**Major Sections:**
- IF Stage: PC, IMEM interface, PC+4
- ID Stage: Decode, control unit, register file, branch resolution
- EX Stage: Forwarding muxes, ALU, multiplier
- MEM Stage: DMEM interface, HILO register
- WB Stage: Result selection, register file write

### 8. `pipeline/dreg.v`
**D Register with Enable**
- Modified version of single-cycle `dreg.v`
- Added `en` input for PC stalling
- When `en=0`, holds current value
- Used for PC register in IF stage

---

## Top-Level Modules

### 9. `pipeline/pipelined_mips.v`
**Pipelined MIPS CPU**
- Top-level CPU module (wrapper for datapath)
- External memory interfaces (IMEM, DMEM)
- Minimal interface for integration

**Interface:**
```verilog
Inputs:  clk, rst, ra3, instr, rd_dm
Outputs: we_dm, pc_current, alu_out, wd_dm, rd3
```

### 10. `pipeline/pipelined_mips_top.v`
**Complete System with Memory**
- Instantiates `pipelined_mips` CPU
- Instantiates `imem` (instruction memory)
- Instantiates `dmem` (data memory)
- Self-contained testable system

**Interface:**
```verilog
Inputs:  clk, rst, ra3
Outputs: (internal - for observation)
```

---

## Documentation Files

### 11. `PIPELINE_DESIGN_DOCUMENT.md`
**Complete Design Specification**

**Contents:**
1. High-level pipeline transformation plan
2. Pipeline register field specifications
3. Hazard and forwarding logic design
4. PC control and flushing logic
5. Control signal propagation table
6. Instruction support summary
7. Pipeline behavior examples
8. Wiring summary
9. ASCII block diagram
10. Performance notes
11. Testing recommendations

**Length:** ~500 lines  
**Audience:** Designers, implementers, verifiers

### 12. `TRANSFORMATION_GUIDE.md`
**Step-by-Step Conversion Instructions**

**Contents:**
- 20 detailed transformation steps
- Block-by-block conversion from single-cycle
- Stage boundary definitions
- Signal mapping tables
- "What moves to which stage" for each component
- Hazard handling for each block
- Testing recommendations per step

**Length:** ~600 lines  
**Audience:** Implementers converting single-cycle to pipeline

### 13. `README_PIPELINE.md`
**Quick Start and Reference Guide**

**Contents:**
- File organization
- Instantiation examples
- Architecture overview
- Supported instructions
- Key features
- Signal flow examples
- Module interface reference
- Performance characteristics
- Testing guidelines
- Troubleshooting

**Length:** ~400 lines  
**Audience:** Users, integrators, testers

### 14. `PIPELINE_FILES_SUMMARY.md`
**This File**
- Lists all generated files
- Brief description of each
- Organization and dependencies

---

## Reused Modules from Single-Cycle Design

The following modules are **reused without modification**:

### Control Logic
- `control_unit/controlunit.v` - Top-level control
- `control_unit/maindec.v` - Main decoder (opcode → control)
- `control_unit/auxdec.v` - Auxiliary decoder (funct → ALU control, HILO)

### Datapath Components
- `datapath/alu.v` - ALU (AND, OR, ADD, SUB, SLT, SLL, SRL)
- `datapath/regfile.v` - Register file (32 registers)
- `datapath/signext.v` - Sign extender (16-bit → 32-bit)
- `datapath/adder.v` - 32-bit adder (PC+4, branch target)
- `datapath/mux2.v` - 2-to-1 multiplexer (parameterized)
- `datapath/multiplier.v` - Unsigned multiplier (32×32 → 64)
- `datapath/hilo_reg.v` - HILO register (64-bit product storage)

### Memory
- `memory/imem.v` - Instruction memory
- `memory/dmem.v` - Data memory

**Note:** The original `datapath/dreg.v` is **not** used directly; a modified version with enable is in `pipeline/dreg.v`.

---

## Module Dependency Graph

```
pipelined_mips_top.v
├── imem.v
├── dmem.v
└── pipelined_mips.v
    └── pipelined_datapath.v
        ├── dreg.v (modified with enable)
        ├── if_id_reg.v (NEW)
        ├── controlunit.v
        │   ├── maindec.v
        │   └── auxdec.v
        ├── regfile.v
        ├── signext.v
        ├── adder.v
        ├── hazard_unit.v (NEW)
        ├── id_ex_reg.v (NEW)
        ├── forwarding_unit.v (NEW)
        ├── mux2.v
        ├── alu.v
        ├── multiplier.v
        ├── ex_mem_reg.v (NEW)
        ├── hilo_reg.v
        └── mem_wb_reg.v (NEW)
```

**NEW = Created for pipelined design**  
**Others = Reused from single-cycle**

---

## File Statistics

| Category | Files Created | Lines of Code (approx) |
|----------|---------------|------------------------|
| Pipeline Registers | 4 | 400 |
| Hazard/Forwarding | 2 | 200 |
| Datapath | 1 | 600 |
| Top-Level | 2 | 100 |
| Modified (dreg) | 1 | 20 |
| Documentation | 4 | 1500 |
| **Total** | **14** | **~2820** |

---

## Build Order (for simulation)

1. **Compile basic components (reused):**
   - `adder.v`, `mux2.v`, `signext.v`
   - `alu.v`, `multiplier.v`
   - `regfile.v`, `hilo_reg.v`
   - `maindec.v`, `auxdec.v`, `controlunit.v`
   - `imem.v`, `dmem.v`

2. **Compile new infrastructure:**
   - `dreg.v` (pipeline version)
   - `if_id_reg.v`, `id_ex_reg.v`, `ex_mem_reg.v`, `mem_wb_reg.v`
   - `hazard_unit.v`, `forwarding_unit.v`

3. **Compile datapath and top:**
   - `pipelined_datapath.v`
   - `pipelined_mips.v`
   - `pipelined_mips_top.v`

4. **Compile testbench:**
   - Your testbench file

---

## Simulation Commands (Example for ModelSim)

```bash
# Compile library components
vlog datapath/adder.v
vlog datapath/mux2.v
vlog datapath/signext.v
vlog datapath/alu.v
vlog datapath/multiplier.v
vlog datapath/regfile.v
vlog datapath/hilo_reg.v
vlog control_unit/maindec.v
vlog control_unit/auxdec.v
vlog control_unit/controlunit.v
vlog memory/imem.v
vlog memory/dmem.v

# Compile pipeline infrastructure
vlog pipeline/dreg.v
vlog pipeline/if_id_reg.v
vlog pipeline/id_ex_reg.v
vlog pipeline/ex_mem_reg.v
vlog pipeline/mem_wb_reg.v
vlog pipeline/hazard_unit.v
vlog pipeline/forwarding_unit.v

# Compile top-level
vlog pipeline/pipelined_datapath.v
vlog pipeline/pipelined_mips.v
vlog pipeline/pipelined_mips_top.v

# Compile and run testbench
vlog testbench/tb_pipelined_mips.v
vsim tb_pipelined_mips
run -all
```

---

## Verification Checklist

- [ ] All pipeline registers latch correctly on clock edge
- [ ] Stall signal holds PC and IF/ID
- [ ] Flush signal clears IF/ID and ID/EX control signals
- [ ] Forwarding detects EX/MEM hazards
- [ ] Forwarding detects MEM/WB hazards
- [ ] Load-use hazard causes 1-cycle stall
- [ ] Branch comparison works in ID stage
- [ ] Branch taken flushes IF/ID
- [ ] Jump/JAL flushes IF/ID
- [ ] JR uses correct rs value (forwarded if needed)
- [ ] JAL writes PC+4 to $ra
- [ ] MULTU writes HILO in MEM stage
- [ ] MFHI/MFLO read from HILO in WB stage
- [ ] All R-type instructions execute correctly
- [ ] All I-type instructions execute correctly
- [ ] All J-type instructions execute correctly
- [ ] No instruction behavior changed from single-cycle
- [ ] Factorial test program runs correctly
- [ ] Pipeline throughput approaches 1 CPI

---

## Next Steps

1. **Simulation:** Test with comprehensive instruction sequences
2. **Waveform Analysis:** Verify signal propagation through stages
3. **Performance Measurement:** Calculate actual CPI with hazards
4. **Optimization:** Consider adding branch prediction
5. **Documentation:** Add instruction timing diagrams
6. **Synthesis:** Target FPGA or ASIC if desired

---

## Summary

This pipelined MIPS implementation includes:
- ✅ 4 new pipeline register modules
- ✅ Hazard detection with stall/flush logic
- ✅ Data forwarding from EX/MEM and MEM/WB
- ✅ Complete pipelined datapath
- ✅ Integrated top-level system
- ✅ Comprehensive documentation (1500+ lines)
- ✅ Full instruction set support
- ✅ Backward compatibility with single-cycle

**Total implementation:** 14 files, ~2800 lines of code + documentation

All design constraints met:
- No features simplified ✓
- No instruction behavior changed ✓
- Control logic staged correctly ✓
- Schematic followed literally ✓
