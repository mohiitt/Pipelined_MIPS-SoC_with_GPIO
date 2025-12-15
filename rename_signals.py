#!/usr/bin/env python3
"""
Signal Renaming Script
Renames signals across all Verilog files according to new naming convention
"""

import os
import re
import glob

RENAME_MAP = {
    'MemToReg': 'dm2reg',
    'RegDst': 'reg_dst',
    'ALUSrc': 'alu_src',
    'Jump': 'jump',
    'Branch': 'branch',
    'Zero': 'alu_zero',
    'PCSrc': 'pc_src',
    'MemWrite': 'we_dm',
    'RegWrite': 'we_reg',
    'ALUControl': 'alu_ctrl',
    'SrcA': 'alu_pa',
    'SrcB': 'alu_pb',
    'ALUResult': 'alu_out',
    'Instr': 'instr',
    'WriteReg': 'wa_reg',
    'Result': 'wd_rf',
    'WriteData': 'wd_dm',
    'ReadData': 'rd_dm',
    'SignImm': 'sext_imm',
    'PC': 'pc_current',
    'PCPlus4': 'pc_next',
    'PCBranch': 'bta',
    'PCJump': 'jta',
}

def rename_in_file(filepath):
    """Rename signals in a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        for old_name, new_name in sorted(RENAME_MAP.items(), key=lambda x: -len(x[0])):
            pattern = r'\b' + re.escape(old_name) + r'\b'
            content = re.sub(pattern, new_name, content)
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {filepath}")
            return True
        else:
            return False
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    root_dir = os.getcwd()
    verilog_files = []
    
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if '.git' in dirpath:
            continue
        for filename in filenames:
            if filename.endswith('.v'):
                verilog_files.append(os.path.join(dirpath, filename))
    
    print(f"Found {len(verilog_files)} Verilog files")
    print("=" * 60)
    
    updated_count = 0
    for filepath in verilog_files:
        if rename_in_file(filepath):
            updated_count += 1
    
    print("=" * 60)
    print(f"Updated {updated_count} files")

if __name__ == '__main__':
    main()
