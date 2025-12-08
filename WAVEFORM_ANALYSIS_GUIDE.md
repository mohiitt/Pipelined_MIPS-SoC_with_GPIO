# Comprehensive Waveform Analysis Guide for Pipelined MIPS

## Your Current Issue: XXXXXXXX After Jump

**What you're seeing is CORRECT pipelined behavior:**

```
Instruction 18: 08000000  → J 0x00000 (jump to address 0)
                 ↓
           Pipeline FLUSH occurs
                 ↓
        IF/ID register cleared → XXXXXXXX appears
                 ↓
        PC jumps to 0x00, fetch resumes
```

This is a **control hazard** - the pipeline correctly:
1. Detects the jump in ID stage
2. Flushes the incorrectly fetched instruction
3. Redirects PC to target address

The X's show the bubble (NOP) inserted during the flush.

---

## Essential Waveforms for Pipeline Analysis

### **Group 1: Pipeline Stages (Instruction Flow)**
These show how instructions move through the 5 stages:

```tcl
add_wave -divider "PIPELINE STAGES - Instruction Flow"
add_wave -radix hexadecimal {{/tb_pipelined_mips_advanced/DUT/pc}}
add_wave -radix hexadecimal -label "IF: instr_F" {{/tb_pipelined_mips_advanced/DUT/instr}}
add_wave -radix hexadecimal -label "ID: instr_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/instr_D}}
add_wave -radix hexadecimal -label "ID: PC+4_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/pc_plus4_D}}
add_wave -radix hexadecimal -label "EX: rs_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rs_E}}
add_wave -radix hexadecimal -label "EX: rt_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rt_E}}
add_wave -radix hexadecimal -label "EX: ALU_out" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_E}}
add_wave -radix hexadecimal -label "MEM: ALU_out_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_M}}
add_wave -radix hexadecimal -label "MEM: wd_dm_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/wd_dm_M}}
add_wave -label "MEM: we_dm_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_dm_M}}
add_wave -radix hexadecimal -label "WB: write_reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/write_reg_W}}
add_wave -label "WB: we_reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_W}}
```

**What to look for:**
- Instructions flowing like a conveyor belt
- 5-cycle latency (instruction takes 5 cycles from IF to WB)
- Throughput of 1 instruction/cycle (in ideal case)

---

### **Group 2: Hazard Detection (Stalls & Flushes)**
Shows when pipeline stalls or flushes:

```tcl
add_wave -divider "HAZARD DETECTION"
add_wave -label "Stall_F (PC stalled)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/stall_F}}
add_wave -label "Stall_D (IF/ID stalled)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/stall_D}}
add_wave -label "Flush_D (IF/ID flushed)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/flush_D}}
add_wave -label "Flush_E (ID/EX flushed)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/flush_E}}
add_wave -label "Branch_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/branch_D}}
add_wave -label "Jump_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/jump_D}}
add_wave -label "JumpReg_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/jump_reg_D}}
add_wave -label "PC_src_D (branch taken)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/pc_src_D}}
```

**What to look for:**
- Stall = 1 when load-use hazard detected
- Flush_D = 1 after branches/jumps (this is why you see XXXXXXXX)
- Count stall cycles to calculate CPI

---

### **Group 3: Data Forwarding**
Shows forwarding paths avoiding stalls:

```tcl
add_wave -divider "DATA FORWARDING"
add_wave -radix binary -label "ForwardA [00=RF, 01=WB, 10=MEM]" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/forward_A}}
add_wave -radix binary -label "ForwardB [00=RF, 01=WB, 10=MEM]" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/forward_B}}
add_wave -radix hexadecimal -label "ALU_A_input (after fwd)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pa_fwd}}
add_wave -radix hexadecimal -label "ALU_B_input (after fwd)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pb_fwd}}
add_wave -radix hexadecimal -label "RF_read1 (rd1_E)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd1_E}}
add_wave -radix hexadecimal -label "RF_read2 (rd2_E)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd2_E}}
add_wave -radix hexadecimal -label "FWD_from_MEM" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_M}}
add_wave -radix hexadecimal -label "FWD_from_WB" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/result_W}}
```

**What to look for:**
- ForwardA/B = 2'b10 when forwarding from MEM stage
- ForwardA/B = 2'b01 when forwarding from WB stage
- ALU inputs change based on forwarding (not just register file)

---

### **Group 4: Register File Changes**
Track specific registers being written:

```tcl
add_wave -divider "REGISTER FILE (Key Registers)"
add_wave -radix hexadecimal -label "$0 (zero)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[0]}}
add_wave -radix hexadecimal -label "$2 (v0)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[2]}}
add_wave -radix hexadecimal -label "$3 (v1)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[3]}}
add_wave -radix hexadecimal -label "$4 (a0)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[4]}}
add_wave -radix hexadecimal -label "$5 (a1)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[5]}}
add_wave -radix hexadecimal -label "$7 (a3)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[7]}}
add_wave -radix hexadecimal -label "$8 (t0)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[8]}}
add_wave -radix hexadecimal -label "$9 (t1)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[9]}}
```

**What to look for:**
- Register values updating in WB stage (5 cycles after fetch)
- Verify computation results are correct

---

### **Group 5: Control Signals Through Pipeline**
Shows control signals propagating:

```tcl
add_wave -divider "CONTROL SIGNALS PROPAGATION"
add_wave -label "ID: we_reg_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_D}}
add_wave -label "EX: we_reg_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_E}}
add_wave -label "MEM: we_reg_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_M}}
add_wave -label "WB: we_reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_W}}
add_wave -radix hexadecimal -label "ID: alu_ctrl_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_ctrl_D}}
add_wave -radix hexadecimal -label "EX: alu_ctrl_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_ctrl_E}}
add_wave -label "ID: dm2reg_D (LW)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/dm2reg_D}}
add_wave -label "EX: dm2reg_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/dm2reg_E}}
```

**What to look for:**
- Control signals move one stage per cycle
- Flushed instructions have all control = 0

---

### **Group 6: Memory Operations**
Track data memory accesses:

```tcl
add_wave -divider "MEMORY OPERATIONS"
add_wave -radix hexadecimal -label "DMEM_addr" {{/tb_pipelined_mips_advanced/DUT/data_addr}}
add_wave -radix hexadecimal -label "DMEM_write_data" {{/tb_pipelined_mips_advanced/DUT/write_data}}
add_wave -radix hexadecimal -label "DMEM_read_data" {{/tb_pipelined_mips_advanced/DUT/read_data}}
add_wave -label "DMEM_write_enable" {{/tb_pipelined_mips_advanced/DUT/mem_write}}
```

**What to look for:**
- SW instructions writing to memory in MEM stage
- LW instructions reading in MEM stage
- Load-use stalls when LW result needed immediately

---

## Comparison: Single-Cycle vs Pipelined

### **Metrics to Compare:**

| Metric | Single-Cycle | Pipelined | How to Measure |
|--------|-------------|-----------|----------------|
| **Clock Period** | Long (~50ns) | Short (~10ns) | Time between clk edges |
| **CPI** | 1.0 | ~1.1-1.3 | Total cycles / Instructions |
| **Execution Time** | High | Low (~5x faster) | Clock × Cycles |
| **Latency** | 1 cycle | 5 cycles | Cycles per instruction |
| **Throughput** | 1 inst/long_cycle | 1 inst/short_cycle | Much higher! |

### **Key Observations:**

**Single-Cycle:**
- Every instruction completes in 1 clock cycle
- Clock must be slow enough for longest path (LW)
- PC increments every cycle
- No hazards, no forwarding needed

**Pipelined:**
- 5 instructions executing simultaneously (different stages)
- Faster clock (shortest stage, not entire datapath)
- PC may stall (hazards)
- Forwarding reduces stalls
- Control hazards cause flushes (XXXXXXXX you see)

---

## Your Program Analysis (memfile.dat)

```assembly
0: 20020005    addi $v0, $zero, 5      # $2 = 5
1: 2003000C    addi $v1, $zero, 12     # $3 = 12
2: 2067FFF7    addi $a3, $v1, -9       # $7 = 12-9 = 3
3: 00E22025    or   $a0, $a3, $v0      # $4 = 3|5 = 7
4: 00642824    and  $a1, $v1, $a0      # $5 = 12&7 = 4
5: 00A42820    add  $a1, $a1, $a0      # $5 = 4+7 = 11
6: 10E5000A    beq  $a3, $a1, L1       # 3≠11, no branch
7: 0064202A    slt  $a0, $v1, $a0      # $4 = (12<7)=0
8: 10040001    beq  $zero, $a0, L2     # 0=0, branch!
9: 20050000    addi $a1, $zero, 0      # SKIPPED (flushed)
A: 00E2202A    slt  $a0, $a3, $v0      # $4 = (3<5)=1
B: 00853820    add  $a3, $a0, $a1      # $7 = 1+11=12
C: 00E23822    sub  $a3, $a3, $v0      # $7 = 12-5=7
D: AC670044    sw   $a3, 68($v1)       # MEM[12+68]=7
E: 8C020050    lw   $v0, 80($zero)     # $2 = MEM[80]
F: 08000011    j    L3                 # Jump
10: 20020001   addi $v0, $zero, 1      # SKIPPED
11: AC020054   sw   $v0, 84($zero)     # MEM[84]=$2
12: 08000000   j    0                  # Jump to start
```

**Expected Hazards:**
- **Line 8-9:** Branch taken → flush line 9 (XXXXXXXX)
- **Line F-10:** Jump → flush line 10 (XXXXXXXX)
- **Line 12:** Jump → flush next instruction (XXXXXXXX) ← **This is what you're seeing!**

---

## Quick Vivado TCL Script

Save this as `add_pipeline_waves.tcl`:

```tcl
# Remove old waves
remove_wave -all

# Clock and Reset
add_wave {{/tb_pipelined_mips_advanced/clk}}
add_wave {{/tb_pipelined_mips_advanced/rst}}

# Pipeline Stages
add_wave -divider "PIPELINE STAGES"
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/pc}}
add_wave -radix hex -label "IF: instr" {{/tb_pipelined_mips_advanced/DUT/instr}}
add_wave -radix hex -label "ID: instr_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/instr_D}}
add_wave -radix hex -label "EX: ALU_out" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_E}}
add_wave -radix hex -label "MEM: ALU_out_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_M}}
add_wave -radix hex -label "WB: write_reg" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/write_reg_W}}

# Hazards
add_wave -divider "HAZARDS & CONTROL"
add_wave {{/tb_pipelined_mips_advanced/DUT/cpu/dp/stall_F}}
add_wave {{/tb_pipelined_mips_advanced/DUT/cpu/dp/stall_D}}
add_wave {{/tb_pipelined_mips_advanced/DUT/cpu/dp/flush_D}}
add_wave {{/tb_pipelined_mips_advanced/DUT/cpu/dp/flush_E}}
add_wave {{/tb_pipelined_mips_advanced/DUT/cpu/dp/branch_D}}
add_wave {{/tb_pipelined_mips_advanced/DUT/cpu/dp/jump_D}}

# Forwarding
add_wave -divider "FORWARDING"
add_wave -radix binary {{/tb_pipelined_mips_advanced/DUT/cpu/dp/forward_A}}
add_wave -radix binary {{/tb_pipelined_mips_advanced/DUT/cpu/dp/forward_B}}
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pa_fwd}}
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pb_fwd}}

# Register File
add_wave -divider "REGISTER FILE"
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[2]}}
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[3]}}
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[4]}}
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[5]}}
add_wave -radix hex {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[7]}}

# Run
run 600ns
```

**Use in Vivado:**
```tcl
source C:/Users/Checkout/Desktop/MIPS_single_cycle_patched/single_cycle_mips_source_initial/add_pipeline_waves.tcl
```

---

## Summary

✅ **Your pipeline is working correctly!**
- XXXXXXXX after `08000000` is **expected** (pipeline flush from jump)
- 50ns reduction is **good** (faster clock period)
- Forwarding signals toggling show hazard resolution

📊 **Add these waveforms to fully analyze:**
1. All 5 pipeline stage outputs
2. Stall/flush signals (explains XXXXXXXX)
3. Forwarding controls (shows hazard avoidance)
4. Register file updates (verify computation)

🔍 **Next Steps:**
1. Count stall cycles to calculate actual CPI
2. Compare execution time vs single-cycle
3. Identify which instructions cause hazards
4. Verify final register/memory values are correct

Would you like me to create a complete Vivado waveform configuration file (.wcfg) with all these signals pre-configured?
