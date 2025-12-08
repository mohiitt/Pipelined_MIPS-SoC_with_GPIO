# Vivado Simulation Guide for Pipelined MIPS

## Step 1: Create Vivado Project

1. **Open Vivado**
2. Click **"Create Project"**
3. Project name: `pipelined_mips`
4. Project location: `C:/Users/Checkout/Desktop/MIPS_single_cycle_patched/vivado_project`
5. Project type: **RTL Project**
6. Check **"Do not specify sources at this time"**
7. Select your target FPGA (e.g., `xc7a35tcpg236-1` for Basys3)
8. Click **Finish**

## Step 2: Add Source Files

### Add Design Sources
In Vivado, click **"Add Sources"** → **"Add or create design sources"**

Add these files in order:
```
Control Unit:
  control_unit/maindec.v
  control_unit/auxdec.v
  control_unit/controlunit.v

Datapath Components:
  datapath/adder.v
  datapath/alu.v
  datapath/signext.v
  datapath/mux2.v
  datapath/regfile.v
  datapath/multiplier.v
  datapath/hilo_reg.v

Memory:
  memory/imem.v
  memory/dmem.v

Pipeline Registers:
  pipeline/dreg.v
  pipeline/if_id_reg.v
  pipeline/id_ex_reg.v
  pipeline/ex_mem_reg.v
  pipeline/mem_wb_reg.v

Pipeline Control:
  pipeline/hazard_unit.v
  pipeline/forwarding_unit.v

Top-Level:
  pipeline/pipelined_datapath.v
  pipeline/pipelined_mips.v
  pipeline/pipelined_mips_top.v
```

### Add Simulation Sources
Click **"Add Sources"** → **"Add or create simulation sources"**

Add:
```
testbench/tb_pipelined_mips_top.v
```

## Step 3: Run Behavioral Simulation

1. In **Flow Navigator**, expand **"Simulation"**
2. Click **"Run Simulation"** → **"Run Behavioral Simulation"**
3. Wait for Vivado to compile and launch simulator

## Step 4: View Waveforms

### Add Signals to Waveform
In the **Objects** window:
1. Select signals you want to monitor
2. Right-click → **"Add to Wave Window"**

**Recommended signals:**
```
Top-Level:
  - clk
  - rst
  - DUT/pc
  - DUT/instr

Pipeline Stages:
  - DUT/cpu/dp/pc_F
  - DUT/cpu/dp/instr_D
  - DUT/cpu/dp/alu_out_E
  - DUT/cpu/dp/alu_out_M
  - DUT/cpu/dp/result_W

Hazard Detection:
  - DUT/cpu/dp/stall_F
  - DUT/cpu/dp/stall_D
  - DUT/cpu/dp/flush_E
  - DUT/cpu/dp/flush_D

Forwarding:
  - DUT/cpu/dp/forward_A
  - DUT/cpu/dp/forward_B

Register File:
  - DUT/cpu/dp/rf/rf[8]   (for $t0)
  - DUT/cpu/dp/rf/rf[9]   (for $t1)
  - DUT/cpu/dp/rf/rf[10]  (for $t2)
```

### Configure Waveform Display
1. **Radix:** Right-click signal → **Radix** → **Hexadecimal**
2. **Group:** Select multiple signals → Right-click → **New Group**
3. **Dividers:** Right-click → **New Divider** (to organize)

## Step 5: Run Simulation

In the **Tcl Console**:
```tcl
# Run for 500ns
run 500ns

# Or run until specific condition
run all

# Restart simulation
restart

# Run for specific number of clock cycles (assuming 10ns period)
run 1000ns
```

## Step 6: Analyze Results

### Check Pipeline Operation
Look for:
- **PC incrementing** by 4 each cycle (unless stalled)
- **Instructions flowing** through pipeline stages
- **Stalls** appearing during load-use hazards
- **Flushes** appearing after branches/jumps
- **Forwarding** signals (2'b01 or 2'b10) during RAW hazards

### Verify Register File
In **Tcl Console**:
```tcl
# Examine register file contents
examine DUT/cpu/dp/rf/rf
```

## Step 7: Save Waveform Configuration

1. **File** → **Simulation Waveform** → **Save Configuration As...**
2. Save as: `pipelined_mips_wave.wcfg`
3. Next time: Load this configuration automatically

## Tcl Script for Automated Simulation

Create `simulate_pipelined.tcl`:
```tcl
# Launch simulation
launch_simulation

# Add all relevant signals
add_wave {{/tb_pipelined_mips_top/clk}}
add_wave {{/tb_pipelined_mips_top/rst}}
add_wave -divider "PC and Instruction"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/pc}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/instr}}
add_wave -divider "Pipeline Stages"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/instr_D}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/alu_out_E}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/alu_out_M}}
add_wave -divider "Hazards"
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/stall_F}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/stall_D}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/flush_E}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/flush_D}}
add_wave -divider "Forwarding"
add_wave -radix binary {{/tb_pipelined_mips_top/DUT/cpu/dp/forward_A}}
add_wave -radix binary {{/tb_pipelined_mips_top/DUT/cpu/dp/forward_B}}
add_wave -divider "Register File"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/rf/rf[8]}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/rf/rf[9]}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/rf/rf[10]}}

# Run simulation
run 500ns

# Save waveform
save_wave_config pipelined_mips.wcfg
```

Run in Vivado Tcl Console:
```tcl
source simulate_pipelined.tcl
```

## Troubleshooting

### Issue: Signals show 'X' (undefined)
- **Cause:** Not enough time elapsed or reset not deasserted
- **Fix:** Run simulation longer, check reset signal

### Issue: Compilation errors
- **Cause:** Missing files or syntax errors
- **Fix:** Check **Messages** tab, verify all files added

### Issue: Simulation runs forever
- **Cause:** No $finish in testbench
- **Fix:** Click **"Stop"** button or press Ctrl+C in Tcl Console

### Issue: Can't see internal signals
- **Cause:** Hierarchy not expanded
- **Fix:** In **Scope** window, expand DUT → cpu → dp

## Export Waveform as Image

1. **File** → **Export** → **Export Waveform Graphics**
2. Choose format: PNG, SVG, or PDF
3. Save for documentation

---

**You're ready to simulate! Click "Run Simulation" in Vivado.**
