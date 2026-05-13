# Quick Vivado TCL Script - Run Pipelined MIPS Simulation

# Set project paths
set project_name "pipelined_mips"
set project_dir "C:/Users/Checkout/Desktop/MIPS_single_cycle_patched/vivado_project"
set source_dir "C:/Users/Checkout/Desktop/MIPS_single_cycle_patched/single_cycle_mips_source_initial"

# Create project (comment out if project already exists)
# create_project $project_name $project_dir -part xc7a35tcpg236-1 -force

# Add design sources
add_files -fileset sources_1 [list \
    $source_dir/control_unit/maindec.v \
    $source_dir/control_unit/auxdec.v \
    $source_dir/control_unit/controlunit.v \
    $source_dir/datapath/adder.v \
    $source_dir/datapath/alu.v \
    $source_dir/datapath/signext.v \
    $source_dir/datapath/mux2.v \
    $source_dir/datapath/regfile.v \
    $source_dir/datapath/multiplier.v \
    $source_dir/datapath/hilo_reg.v \
    $source_dir/memory/imem.v \
    $source_dir/memory/dmem.v \
    $source_dir/pipeline/dreg.v \
    $source_dir/pipeline/if_id_reg.v \
    $source_dir/pipeline/id_ex_reg.v \
    $source_dir/pipeline/ex_mem_reg.v \
    $source_dir/pipeline/mem_wb_reg.v \
    $source_dir/pipeline/hazard_unit.v \
    $source_dir/pipeline/forwarding_unit.v \
    $source_dir/pipeline/pipelined_datapath.v \
    $source_dir/pipeline/pipelined_mips.v \
    $source_dir/pipeline/pipelined_mips_top.v \
]

# Add simulation sources
add_files -fileset sim_1 $source_dir/testbench/tb_pipelined_mips_top.v

# Set top module for simulation
set_property top tb_pipelined_mips_top [get_filesets sim_1]

# Launch simulation
launch_simulation

# Add waveforms
add_wave {{/tb_pipelined_mips_top/clk}}
add_wave {{/tb_pipelined_mips_top/rst}}
add_wave -divider "Fetch Stage"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/pc}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/instr}}
add_wave -divider "Decode Stage"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/instr_D}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/rd1_D}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/rd2_D}}
add_wave -divider "Execute Stage"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/alu_out_E}}
add_wave -divider "Memory Stage"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/alu_out_M}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/we_dm_M}}
add_wave -divider "Writeback Stage"
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/we_reg_W}}
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/write_reg_W}}
add_wave -divider "Hazard Signals"
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/stall_F}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/stall_D}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/flush_E}}
add_wave {{/tb_pipelined_mips_top/DUT/cpu/dp/flush_D}}
add_wave -divider "Forwarding Signals"
add_wave -radix binary {{/tb_pipelined_mips_top/DUT/cpu/dp/forward_A}}
add_wave -radix binary {{/tb_pipelined_mips_top/DUT/cpu/dp/forward_B}}
add_wave -divider "Register File (first 16 regs)"
add_wave -radix hexadecimal {{/tb_pipelined_mips_top/DUT/cpu/dp/rf/rf}}

# Run simulation
run 500ns

puts "Simulation complete! Check waveform window."
