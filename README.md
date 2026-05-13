# Pipelined MIPS System-on-Chip (SoC) with GPIO

## Project Overview

This project implements a complete **5-stage pipelined MIPS processor** integrated with a memory-mapped **General Purpose Input/Output (GPIO)** module, forming a functional System-on-Chip (SoC). 

The initial single-cycle MIPS CPU has been fully transformed into a pipelined architecture, featuring comprehensive hazard detection, data forwarding, and control hazard handling. It is integrated alongside an interactive GPIO module that allows the CPU to interface with external hardware pins.

### Key Work Accomplished
- **Pipelined CPU Core**: Transformed a single-cycle datapath into a 5-stage pipeline (IF, ID, EX, MEM, WB).
- **Hazard Management**: Engineered data forwarding (EX/MEM and MEM/WB to EX) and load-use/branch hazard stalling to maintain instruction throughput.
- **Advanced Instruction Support**: Fully supports R-type, I-type, and J-type instructions, including hardware multiplication (`multu`, `mfhi`, `mflo`) and jump-and-link (`jal`).
- **Memory-Mapped I/O Integration**: Designed and verified a `gpio.v` module providing 32-bit `GPIO_IN` and `GPIO_OUT` registers accessible via memory-mapped addresses (`0x00000000` and `0x00000004`).
- **Comprehensive Verification**: Developed testbenches and generated detailed waveforms (`.vcd` files) validating the individual components, datapath forwarding, memory/GPIO interactions, and overall SoC behavior.
- **Performance Evaluation**: Conducted simulations establishing the performance gains (CPI ~1) of the pipelined architecture over its single-cycle counterpart.

---

## 1. Pipelined MIPS CPU Architecture

### Pipeline Stages
| Stage | Name | Operations |
|-------|------|------------|
| **IF** | Instruction Fetch | Fetch instruction, calculate PC+4 |
| **ID** | Instruction Decode | Decode, generate controls, read registers, branch resolution |
| **EX** | Execute | ALU operation, forwarding, multiplication |
| **MEM** | Memory Access | Read/write data memory, write HILO, interact with GPIO |
| **WB** | Writeback | Select result, write register file |

### Pipeline Registers
- **IF/ID:** Latches instruction and PC+4
- **ID/EX:** Latches control signals, register values, immediate, addresses
- **EX/MEM:** Latches ALU result, memory data, control signals
- **MEM/WB:** Latches writeback data, control signals, HILO values

### Hazard Handling
- **Data Hazards:** Resolved via Data Forwarding (EX/MEM → EX and MEM/WB → EX) and Load-Use Stalls (1 cycle stall).
- **Control Hazards:** Early branch resolution in ID stage, flushing IF/ID on branches/jumps, stalling for `jr` dependencies.

---

## 2. GPIO Memory-Mapped Module

The `gpio.v` module provides two 32-bit registers accessible via memory-mapped I/O, seamlessly integrated with the pipelined CPU's data memory interface.

### Memory Map
| Address    | Register  | Access | Description |
|------------|-----------|--------|-------------|
| 0x00000000 | GPIO_IN   | R      | Read-only input register (synchronized with external `gpio_in_pins`) |
| 0x00000004 | GPIO_OUT  | R/W    | Read/write output register (drives external `gpio_out_pins`) |

---

## Quick Start & File Organization

The project files have been modularized into respective folders for clarity:

- `control_unit/`, `datapath/`, `memory/`, `mips/`, `pipeline/`, `soc/`, `integrated/`: Core Verilog RTL files for the pipelined CPU and SoC integration.
- `testbench/`: Verilog testbenches for all modules.
- `docs/`: Comprehensive design documentation and project manuals.
- `scripts/`: TCL and Python scripts for Vivado simulation and performance analysis.
- `sim_workspace/`: Pre-compiled simulation binaries (`.vvp`), logs, and waveform (`.vcd`) outputs.
- `images/`: Architectural diagrams and waveform captures.

### Running a Simulation

Use the testbenches within the `testbench/` folder with your preferred simulator (e.g., Icarus Verilog or Vivado) to verify the top-level functionality.

```bash
# Example using Icarus Verilog
iverilog -o sim_workspace/soc_sim.vvp pipeline/*.v soc/*.v testbench/tb_soctop_sim.v
vvp sim_workspace/soc_sim.vvp
```

---

## Documentation

For an in-depth understanding, please refer to the files in the `docs/` directory:
- `PIPELINE_DESIGN_DOCUMENT.md`: Complete architectural specification.
- `PIPELINE_FILES_SUMMARY.md`: Detailed breakdown of pipeline modules.
- `VIVADO_SIMULATION_GUIDE.md`: Guide for running simulations in Xilinx Vivado.
- `PERFORMANCE_ANALYSIS.md`: Metrics and comparisons between pipelined and single-cycle CPUs.
