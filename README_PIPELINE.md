# Pipelined MIPS CPU Implementation

## Project Overview

This project contains a complete transformation of a single-cycle MIPS CPU into a fully functional **5-stage pipelined processor** with comprehensive hazard detection, data forwarding, and control hazard handling.

---

## Quick Start

### File Organization

```
pipeline/
├── pipelined_mips_top.v       # Top-level with IMEM/DMEM
├── pipelined_mips.v           # CPU wrapper
├── pipelined_datapath.v       # Complete pipelined datapath
├── if_id_reg.v                # IF/ID pipeline register
├── id_ex_reg.v                # ID/EX pipeline register
├── ex_mem_reg.v               # EX/MEM pipeline register
├── mem_wb_reg.v               # MEM/WB pipeline register
├── hazard_unit.v              # Hazard detection logic
├── forwarding_unit.v          # Data forwarding logic
└── dreg.v                     # D register with enable (for PC)

Documentation/
├── PIPELINE_DESIGN_DOCUMENT.md    # Complete design specification
├── TRANSFORMATION_GUIDE.md        # Step-by-step conversion guide
└── README_PIPELINE.md             # This file
```

### Instantiation Example

```verilog
module testbench;
    reg clk, rst;
    reg [4:0] ra3;

    pipelined_mips_top dut (
        .clk(clk),
        .rst(rst),
        .ra3(ra3)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #20 rst = 0;
        // Test execution...
    end
endmodule
```

---

## Architecture Overview

### Pipeline Stages

| Stage | Name | Operations |
|-------|------|------------|
| **IF** | Instruction Fetch | Fetch instruction, calculate PC+4 |
| **ID** | Instruction Decode | Decode, generate controls, read registers, branch resolution |
| **EX** | Execute | ALU operation, forwarding, multiplication |
| **MEM** | Memory Access | Read/write data memory, write HILO |
| **WB** | Writeback | Select result, write register file |

### Pipeline Registers

- **IF/ID:** Latches instruction and PC+4
- **ID/EX:** Latches control signals, register values, immediate, addresses
- **EX/MEM:** Latches ALU result, memory data, control signals
- **MEM/WB:** Latches writeback data, control signals, HILO values

### Hazard Handling

#### Data Hazards
- **Forwarding:** EX/MEM → EX and MEM/WB → EX
- **Load-Use Stall:** 1 cycle stall when instruction after LW needs loaded data

#### Control Hazards
- **Branch:** Early resolution in ID stage, flush IF/ID on taken
- **Jump/JAL:** Flush IF/ID
- **JR:** Stall until rs is available

---

## Supported Instructions

### R-Type
- **Arithmetic:** ADD, SUB
- **Logical:** AND, OR
- **Comparison:** SLT
- **Shift:** SLL, SRL
- **Jump:** JR
- **Multiply:** MULTU
- **Move:** MFHI, MFLO

### I-Type
- **Arithmetic:** ADDI
- **Memory:** LW, SW
- **Branch:** BEQ

### J-Type
- **Jump:** J, JAL

---

## Key Features

### 1. Data Forwarding
Eliminates most RAW hazards by forwarding results from later stages:
```
add $t0, $t1, $t2   # Result available in EX/MEM
sub $t3, $t0, $t4   # Forwarded to EX stage
```

### 2. Hazard Detection
Automatically detects and handles:
- Load-use hazards (1 cycle stall)
- JR dependencies (stall until register ready)
- Branch dependencies (stall until operands ready)

### 3. Branch Optimization
- Branch decision in ID stage (early resolution)
- Minimizes control hazard penalty to 1 cycle

### 4. HILO Register Support
- MULTU writes 64-bit product to HILO in MEM stage
- MFHI/MFLO read from HILO in WB stage
- Correct pipeline timing maintained

### 5. JAL Support
- Saves PC+4 to $ra
- PC+4 propagates through entire pipeline
- Correct writeback in WB stage

---

## Signal Flow Examples

### Normal Instruction Flow (ADD)
```
Cycle 1: IF  - Fetch instruction
Cycle 2: ID  - Decode, read registers
Cycle 3: EX  - Perform addition
Cycle 4: MEM - (no memory access)
Cycle 5: WB  - Write result to register file
```

### Load-Use with Stall (LW followed by ADD)
```
       1    2    3    4    5    6
LW:    IF   ID   EX   MEM  WB
ADD:        IF   ID   STALL EX  MEM
                       ↑
                   Hazard detected, insert bubble
```

### Forwarding (ADD followed by SUB)
```
       1    2    3    4    5
ADD:   IF   ID   EX   MEM  WB
SUB:        IF   ID   EX   MEM
                       ↑
                   Forward from MEM stage
```

---

## Control Signal Propagation

| Signal | Generated | Used | Path |
|--------|-----------|------|------|
| `branch`, `jump`, `jal`, `jump_reg` | ID | ID | Immediate use |
| `reg_dst`, `alu_src`, `alu_ctrl` | ID | EX | ID/EX |
| `we_dm` | ID | MEM | ID/EX → EX/MEM |
| `dm2reg`, `we_reg` | ID | WB | ID/EX → EX/MEM → MEM/WB |
| `hilo_wd` | ID | MEM | ID/EX → EX/MEM |
| `hilo_mux_ctrl` | ID | WB | ID/EX → EX/MEM → MEM/WB |

---

## Module Interface Reference

### pipelined_mips_top
```verilog
module pipelined_mips_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3    // Test register read address
);
```

### pipelined_mips
```verilog
module pipelined_mips (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3,
    input  wire [31:0] instr,      // From IMEM
    input  wire [31:0] rd_dm,      // From DMEM
    output wire        we_dm,      // To DMEM
    output wire [31:0] pc_current, // To IMEM
    output wire [31:0] alu_out,    // To DMEM (address)
    output wire [31:0] wd_dm,      // To DMEM (write data)
    output wire [31:0] rd3         // Test output
);
```

### hazard_unit
```verilog
module hazard_unit (
    input  wire [4:0]  rs_D,
    input  wire [4:0]  rt_D,
    input  wire        branch_D,
    input  wire        jump_reg_D,
    input  wire [4:0]  rt_E,
    input  wire [4:0]  write_reg_E,
    input  wire        we_reg_E,
    input  wire        dm2reg_E,
    input  wire [4:0]  write_reg_M,
    input  wire        we_reg_M,
    output wire        stall_F,
    output wire        stall_D,
    output wire        flush_E
);
```

### forwarding_unit
```verilog
module forwarding_unit (
    input  wire [4:0]  rs_E,
    input  wire [4:0]  rt_E,
    input  wire [4:0]  write_reg_M,
    input  wire        we_reg_M,
    input  wire [4:0]  write_reg_W,
    input  wire        we_reg_W,
    output wire [1:0]  forward_A,    // 00=no fwd, 01=WB, 10=MEM
    output wire [1:0]  forward_B
);
```

---

## Performance Characteristics

### Ideal Performance
- **CPI:** 1.0 (one instruction per cycle)
- **Throughput:** 5x single-cycle CPU
- **Latency:** 5 cycles per instruction

### With Hazards
- **Load-use:** +1 cycle per occurrence
- **Branch taken:** +1 cycle per occurrence
- **JR with dependency:** +1-2 cycles depending on distance

### Clock Frequency
Pipeline stages are balanced to minimize critical path:
- **IF:** PC + IMEM
- **ID:** Decode + RegFile + Control
- **EX:** Forwarding mux + ALU
- **MEM:** DMEM access
- **WB:** Result mux

---

## Testing Guidelines

### Unit Testing
1. Test each pipeline register independently
2. Verify hazard unit detects all hazard types
3. Verify forwarding unit generates correct controls
4. Test each stage with known inputs

### Integration Testing
1. Run single instruction through pipeline
2. Test back-to-back instructions (forwarding)
3. Test load-use hazards (stalling)
4. Test branches and jumps (flushing)
5. Test MULTU/MFHI/MFLO sequence
6. Test JAL return address

### Functional Testing
Test programs:
- Factorial calculation
- Fibonacci sequence
- Array sorting
- Nested loops
- Function calls with JAL/JR

---

## Comparison: Single-Cycle vs Pipelined

| Aspect | Single-Cycle | Pipelined |
|--------|--------------|-----------|
| **CPI** | 1 | ~1 (with hazards: 1.1-1.3) |
| **Clock Period** | Long (all stages) | Short (one stage) |
| **Throughput** | 1 inst/long_cycle | 1 inst/short_cycle |
| **Latency** | 1 cycle | 5 cycles |
| **Hardware** | One of each unit | Duplicated muxes, registers |
| **Complexity** | Low | High (hazards, forwarding) |

**Example:**
- Single-cycle: 10ns clock → 100 MIPS
- Pipelined: 2ns clock × 1 CPI → 500 MIPS (5x speedup)

---

## Common Issues and Solutions

### Issue: Forwarding not working
**Solution:** Check that `write_reg_M` and `write_reg_W` are correctly propagated through pipeline registers.

### Issue: Stall not working
**Solution:** Verify `stall_F` disables PC register and `stall_D` disables IF/ID register.

### Issue: Branch always flushes
**Solution:** Check branch comparator logic and `zero_D` signal.

### Issue: JAL writes wrong value
**Solution:** Ensure PC+4 propagates through all pipeline stages to WB.

### Issue: MULTU result wrong
**Solution:** Verify product latches in EX/MEM and HILO writes in MEM stage.

---

## Documentation Files

1. **PIPELINE_DESIGN_DOCUMENT.md**
   - Complete architectural specification
   - Pipeline register fields
   - Hazard and forwarding logic
   - Control signal tables
   - Wiring diagrams

2. **TRANSFORMATION_GUIDE.md**
   - Step-by-step conversion from single-cycle
   - Block-by-block transformation instructions
   - Stage boundary definitions
   - Testing recommendations

3. **README_PIPELINE.md** (this file)
   - Quick start guide
   - Usage examples
   - Interface reference

---

## Advanced Topics

### Optimizations
- **Branch prediction:** Add predictor to reduce flush penalty
- **Memory forwarding:** Forward from MEM/WB to MEM for store-after-load
- **Dual-issue:** Fetch/decode two instructions per cycle
- **Out-of-order execution:** Execute independent instructions in parallel

### Extensions
- **Exception handling:** Add exception detection in each stage
- **Cache integration:** Replace IMEM/DMEM with cache controllers
- **FPU pipeline:** Add floating-point execution units
- **Privilege modes:** Add user/kernel mode support

---

## License and Credits

This pipelined MIPS implementation is based on the standard 5-stage MIPS pipeline architecture described in "Computer Organization and Design" by Patterson and Hennessy.

**Key Design Principles:**
- Maintain backward compatibility with single-cycle design
- Support all original instructions
- Minimize hazard penalties through forwarding
- Clear separation of stages for modularity

---

## Contact and Support

For questions or issues:
1. Review PIPELINE_DESIGN_DOCUMENT.md for architecture details
2. Review TRANSFORMATION_GUIDE.md for implementation steps
3. Check signal flow and timing in waveform viewer
4. Verify all pipeline registers latch correctly

**Happy pipelining! 🚀**
