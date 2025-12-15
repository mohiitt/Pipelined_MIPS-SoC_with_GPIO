#!/usr/bin/env python3
"""
Performance Analysis Script for Pipelined MIPS vs SoC-Integrated MIPS
Compares cycle counts for factorial computation with N = 1 to 4
"""

import subprocess
import re
import matplotlib.pyplot as plt
import os
import shutil

N_VALUES = [1, 2, 3, 4]
RESULTS = {
    'pipelined': {},
    'soc_integrated': {}
}

MEMFILE_SOC = 'memfile.dat'
MEMFILE_PIPE = 'memfile1.dat'
MEMFILE_TARGET = 'memfile.dat'

def setup_files():
    """Backup existing files"""
    if os.path.exists(MEMFILE_TARGET):
        shutil.copy2(MEMFILE_TARGET, MEMFILE_TARGET + '.bak')

def restore_files():
    """Restore backed up files"""
    if os.path.exists(MEMFILE_TARGET + '.bak'):
        shutil.move(MEMFILE_TARGET + '.bak', MEMFILE_TARGET)

def compile_sim(output_file, type='soc'):
    """Compile simulation"""

    common_src = [
        '-I', 'pipeline', '-I', 'datapath', '-I', 'control_unit',
        '-I', 'soc', '-I', 'integrated', '-I', 'memory',
        'pipeline/pipelined_mips.v',
        'pipeline/pipelined_datapath.v',
        'pipeline/dreg.v',
        'pipeline/ex_mem_reg.v',
        'pipeline/forwarding_unit.v',
        'pipeline/hazard_unit.v',
        'pipeline/id_ex_reg.v',
        'pipeline/if_id_reg.v',
        'pipeline/mem_wb_reg.v',
        'datapath/adder.v',
        'datapath/alu.v',
        'datapath/hilo_reg.v',
        'datapath/multiplier.v',
        'datapath/mux2.v',
        'datapath/regfile.v',
        'datapath/signext.v',
        'control_unit/controlunit.v',
        'control_unit/maindec.v',
        'control_unit/auxdec.v',
        'memory/dmem.v',
        'memory/imem.v'
    ]

    if type == 'soc':
        src = [
            'testbench/tb_soc_system.v',
            'integrated/soc_system_top.v',
            'soc/soc_top.v',
            'soc/addr_decoder.v',
            'soc/gpio.v',
            'soc/factorial_wrapper.v',
            'soc/fact_accl.v',
        ]
    else:
        src = [
            'testbench/tb_pipelined_mips_top.v',
            'pipeline/pipelined_mips_top.v'
        ]

    cmd = ['iverilog', '-o', output_file] + common_src + src

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Compilation failed for {type}: {result.stderr}")
        return False
    return True

def run_soc_test(n_value):
    """Run SoC test for N"""

    if os.path.exists(MEMFILE_TARGET + '.bak'):
        shutil.copy2(MEMFILE_TARGET + '.bak', MEMFILE_TARGET)

    with open('testbench/tb_soc_system.v', 'r') as f:
        content = f.read()

    expected = 1
    for i in range(1, n_value + 1): expected *= i

    content = re.sub(r'gpio_in = 32\'d\d+;', f'gpio_in = 32\'d{n_value};', content)
    content = re.sub(r'wait\(gpio_out == 32\'d\d+\);', f'wait(gpio_out == 32\'d{expected});', content)
    content = re.sub(r'\[SUCCESS\] GPIO Output updated to %d \(Expected \d+\)',
                     f'[SUCCESS] GPIO Output updated to %d (Expected {expected})', content)

    with open('testbench/tb_soc_system.v', 'w') as f:
        f.write(content)

    if not compile_sim('soc_sim.vvp', 'soc'):
        return None

    res = subprocess.run(['vvp', 'soc_sim.vvp'], capture_output=True, text=True)
    match = re.search(r'Finished in\s+(\d+)\s+cycles', res.stdout)
    return int(match.group(1)) if match else None

def run_pipeline_test(n_value):
    """Run Pipeline test for N"""

    with open(MEMFILE_PIPE, 'r') as f:
        lines = f.readlines()

    new_inst = 0x20040000 | n_value
    lines[1] = f"{new_inst:08x}\n"

    with open(MEMFILE_TARGET, 'w') as f:
        f.writelines(lines)

    if not compile_sim('pipe_sim.vvp', 'pipe'):
        return None

    res = subprocess.run(['vvp', 'pipe_sim.vvp'], capture_output=True, text=True)

    match = re.search(r'Total cycles:\s+(\d+)', res.stdout)
    if not match:

        match = re.search(r'Program finished at cycle\s+(\d+)', res.stdout)

    return int(match.group(1)) if match else None

def generate_graphs(results):
    n_vals = sorted(results['pipelined'].keys())
    pipe_cyc = [results['pipelined'][n] for n in n_vals]
    soc_cyc = [results['soc_integrated'][n] for n in n_vals]
    speedup = [p/s for p,s in zip(pipe_cyc, soc_cyc)]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))

    ax1.plot(n_vals, pipe_cyc, 'o--', label='Software (Pipelined)', color='blue')
    ax1.plot(n_vals, soc_cyc, 's-', label='Hardware (SoC)', color='red')
    ax1.set_xlabel('Input N')
    ax1.set_ylabel('Cycle Count')
    ax1.set_title('Factorial Execution Time')
    ax1.legend()
    ax1.grid(True)

    ax2.bar(n_vals, speedup, color='orange', edgecolor='black')
    ax2.axhline(1, color='red', linestyle='--')
    ax2.set_xlabel('Input N')
    ax2.set_ylabel('Speedup (SW/HW)')
    ax2.set_title('Hardware Acceleration Speedup')
    for i, v in enumerate(speedup):
        ax2.text(i+1, v+0.05, f'{v:.2f}x', ha='center')

    plt.savefig('performance_analysis.png')
    print("Graph saved to performance_analysis.png")

def main():
    setup_files()
    try:
        print("Running Analysis...")
        print(f"{'N':<5} {'Pipeline':<10} {'SoC':<10} {'Speedup':<10}")
        print("-" * 40)

        for n in N_VALUES:
            soc_c = run_soc_test(n)
            pipe_c = run_pipeline_test(n)

            RESULTS['soc_integrated'][n] = soc_c
            RESULTS['pipelined'][n] = pipe_c

            sp = pipe_c / soc_c if soc_c and pipe_c else 0
            print(f"{n:<5} {pipe_c:<10} {soc_c:<10} {sp:.2f}x")

        generate_graphs(RESULTS)

    finally:
        restore_files()

if __name__ == "__main__":
    main()