# ============================================================================
# Comprehensive Waveform Setup for Pipelined MIPS Analysis
# Source this in Vivado Simulator after launching simulation
# Usage: source add_comprehensive_waves.tcl
# ============================================================================

# Clear existing waveforms
catch {remove_wave -all}

# ============================================================================
# BASIC SIGNALS
# ============================================================================
add_wave -divider "========== CLOCK & RESET =========="
add_wave {{/tb_pipelined_mips_advanced/clk}}
add_wave {{/tb_pipelined_mips_advanced/rst}}
add_wave {{/tb_pipelined_mips_advanced/cycle}}

# ============================================================================
# PIPELINE STAGES - Instruction Flow
# ============================================================================
add_wave -divider "========== PIPELINE STAGES =========="
add_wave -group "IF Stage" -radix hexadecimal {{/tb_pipelined_mips_advanced/DUT/pc}}
add_wave -group "IF Stage" -radix hexadecimal -label "instr_F" {{/tb_pipelined_mips_advanced/DUT/instr}}
add_wave -group "IF Stage" -radix hexadecimal -label "pc_plus4_F" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/pc_plus4_F}}

add_wave -group "ID Stage" -radix hexadecimal -label "instr_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/instr_D}}
add_wave -group "ID Stage" -radix hexadecimal -label "pc_plus4_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/pc_plus4_D}}
add_wave -group "ID Stage" -radix hexadecimal -label "rd1_D (rs value)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd1_D}}
add_wave -group "ID Stage" -radix hexadecimal -label "rd2_D (rt value)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd2_D}}
add_wave -group "ID Stage" -radix unsigned -label "rs_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rs_D}}
add_wave -group "ID Stage" -radix unsigned -label "rt_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rt_D}}
add_wave -group "ID Stage" -radix unsigned -label "rd_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd_D}}
add_wave -group "ID Stage" -radix hexadecimal -label "sext_imm_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/sext_imm_D}}

add_wave -group "EX Stage" -radix hexadecimal -label "alu_pa_fwd (A input)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pa_fwd}}
add_wave -group "EX Stage" -radix hexadecimal -label "alu_pb_fwd (B input)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pb_fwd}}
add_wave -group "EX Stage" -radix hexadecimal -label "alu_pb_E (after mux)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_pb_E}}
add_wave -group "EX Stage" -radix hexadecimal -label "alu_out_E (result)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_E}}
add_wave -group "EX Stage" -radix unsigned -label "write_reg_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/write_reg_E}}
add_wave -group "EX Stage" -radix hexadecimal -label "mult_product_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/mult_product_E}}

add_wave -group "MEM Stage" -radix hexadecimal -label "alu_out_M (address)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_M}}
add_wave -group "MEM Stage" -radix hexadecimal -label "wd_dm_M (write data)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/wd_dm_M}}
add_wave -group "MEM Stage" -label "we_dm_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_dm_M}}
add_wave -group "MEM Stage" -radix hexadecimal -label "rd_dm (read data)" {{/tb_pipelined_mips_advanced/DUT/read_data}}
add_wave -group "MEM Stage" -radix unsigned -label "write_reg_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/write_reg_M}}

add_wave -group "WB Stage" -radix hexadecimal -label "alu_out_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_W}}
add_wave -group "WB Stage" -radix hexadecimal -label "rd_dm_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd_dm_W}}
add_wave -group "WB Stage" -radix hexadecimal -label "result_W (final)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/result_W}}
add_wave -group "WB Stage" -radix unsigned -label "write_reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/write_reg_W}}
add_wave -group "WB Stage" -label "we_reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_W}}

# ============================================================================
# HAZARD DETECTION & CONTROL
# ============================================================================
add_wave -divider "========== HAZARDS & STALLS =========="
add_wave -label "STALL_F (PC frozen)" -color "red" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/stall_F}}
add_wave -label "STALL_D (IF/ID frozen)" -color "red" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/stall_D}}
add_wave -label "FLUSH_D (IF/ID cleared)" -color "orange" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/flush_D}}
add_wave -label "FLUSH_E (ID/EX cleared)" -color "orange" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/flush_E}}

add_wave -divider "Control Decisions (ID Stage)"
add_wave -label "branch_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/branch_D}}
add_wave -label "jump_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/jump_D}}
add_wave -label "jump_reg_D (JR)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/jump_reg_D}}
add_wave -label "pc_src_D (branch taken)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/pc_src_D}}
add_wave -radix hexadecimal -label "bta_D (branch target)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/bta_D}}
add_wave -radix hexadecimal -label "jta_D (jump target)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/jta_D}}

# ============================================================================
# DATA FORWARDING
# ============================================================================
add_wave -divider "========== FORWARDING =========="
add_wave -radix binary -label "forward_A [00=RF, 01=WB, 10=MEM]" -color "green" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/forward_A}}
add_wave -radix binary -label "forward_B [00=RF, 01=WB, 10=MEM]" -color "green" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/forward_B}}

add_wave -divider "Forwarding Sources"
add_wave -radix hexadecimal -label "From MEM (alu_out_M)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_out_M}}
add_wave -radix hexadecimal -label "From WB (result_W)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/result_W}}
add_wave -radix hexadecimal -label "From RF (rd1_E)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd1_E}}
add_wave -radix hexadecimal -label "From RF (rd2_E)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rd2_E}}

# ============================================================================
# CONTROL SIGNAL PROPAGATION
# ============================================================================
add_wave -divider "========== CONTROL SIGNALS =========="
add_wave -group "RegWrite" -label "we_reg_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_D}}
add_wave -group "RegWrite" -label "we_reg_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_E}}
add_wave -group "RegWrite" -label "we_reg_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_M}}
add_wave -group "RegWrite" -label "we_reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_reg_W}}

add_wave -group "ALU Control" -radix hexadecimal -label "alu_ctrl_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_ctrl_D}}
add_wave -group "ALU Control" -radix hexadecimal -label "alu_ctrl_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/alu_ctrl_E}}

add_wave -group "Memory Control" -label "we_dm_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_dm_D}}
add_wave -group "Memory Control" -label "we_dm_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_dm_E}}
add_wave -group "Memory Control" -label "we_dm_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/we_dm_M}}

add_wave -group "MemToReg" -label "dm2reg_D" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/dm2reg_D}}
add_wave -group "MemToReg" -label "dm2reg_E" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/dm2reg_E}}
add_wave -group "MemToReg" -label "dm2reg_M" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/dm2reg_M}}
add_wave -group "MemToReg" -label "dm2reg_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/dm2reg_W}}

# ============================================================================
# REGISTER FILE
# ============================================================================
add_wave -divider "========== REGISTER FILE =========="
add_wave -radix hexadecimal -label "$0 (zero)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[0]}}
add_wave -radix hexadecimal -label "$2 (v0)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[2]}}
add_wave -radix hexadecimal -label "$3 (v1)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[3]}}
add_wave -radix hexadecimal -label "$4 (a0)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[4]}}
add_wave -radix hexadecimal -label "$5 (a1)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[5]}}
add_wave -radix hexadecimal -label "$6 (a2)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[6]}}
add_wave -radix hexadecimal -label "$7 (a3)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[7]}}
add_wave -radix hexadecimal -label "$8 (t0)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[8]}}
add_wave -radix hexadecimal -label "$9 (t1)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[9]}}
add_wave -radix hexadecimal -label "$29 (sp)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[29]}}
add_wave -radix hexadecimal -label "$31 (ra)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/rf/rf[31]}}

# ============================================================================
# MEMORY
# ============================================================================
add_wave -divider "========== MEMORY OPERATIONS =========="
add_wave -radix hexadecimal -label "IMEM[pc>>2]" {{/tb_pipelined_mips_advanced/DUT/instruction_memory/rom}}
add_wave -radix hexadecimal -label "DMEM (first 16 words)" {{/tb_pipelined_mips_advanced/DUT/data_memory/ram}}

# ============================================================================
# HILO REGISTERS (for MULTU/MFHI/MFLO)
# ============================================================================
add_wave -divider "========== HILO REGISTERS =========="
add_wave -radix hexadecimal -label "HI" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/hilo/hi}}
add_wave -radix hexadecimal -label "LO" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/hilo/lo}}
add_wave -label "hilo_wd_M (write enable)" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/hilo_wd_M}}
add_wave -radix binary -label "hilo_mux_ctrl_W" {{/tb_pipelined_mips_advanced/DUT/cpu/dp/hilo_mux_ctrl_W}}

# ============================================================================
# Configure waveform display
# ============================================================================
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 10
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# Run simulation
puts "Waveforms configured!"
puts "Running simulation for 600ns..."
run 600ns

puts ""
puts "========================================="
puts "ANALYSIS TIPS:"
puts "========================================="
puts "1. Look for FLUSH_D=1 when you see XXXXXXXX (expected after jumps/branches)"
puts "2. Check forward_A/B for values 01 or 10 (data forwarding active)"
puts "3. Watch STALL signals for load-use hazards"
puts "4. Verify register values update in WB stage (5 cycles after IF)"
puts "5. Count cycles where stall=1 to calculate real CPI"
puts ""
puts "Expected CPI ≈ Total_Cycles / 19 instructions"
puts "Expected: ~1.1-1.3 (due to hazards)"
puts ""
