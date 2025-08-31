#!/usr/bin/env python3
# Extract relaxed geometry from QE relaxation output

import sys
import re
import os

def extract_relaxed_geometry(relax_output_file, system_name):
    '''Extract final relaxed geometry from QE relaxation output'''
    
    if not os.path.exists(relax_output_file):
        print(f"Error: {relax_output_file} not found")
        return False
    
    with open(relax_output_file, 'r') as f:
        content = f.read()
    
    # Find the last ATOMIC_POSITIONS section
    atomic_positions_blocks = re.findall(r'ATOMIC_POSITIONS.*?(?=\n\s*\n|$)', content, re.DOTALL)
    
    if not atomic_positions_blocks:
        print("Error: No ATOMIC_POSITIONS found in output")
        return False
    
    last_positions = atomic_positions_blocks[-1]
    
    # Find the last CELL_PARAMETERS section
    cell_blocks = re.findall(r'CELL_PARAMETERS.*?(?=\n\s*\n|$)', content, re.DOTALL)
    last_cell = cell_blocks[-1] if cell_blocks else None
    
    # Get other necessary information from original input
    input_file = f"../input_files/{system_name}_relax.in"
    
    with open(input_file, 'r') as f:
        original_input = f.read()
    
    # Extract sections that don't change
    control_section = re.search(r'&CONTROL.*?/', original_input, re.DOTALL).group(0)
    system_section = re.search(r'&SYSTEM.*?/', original_input, re.DOTALL).group(0)
    electrons_section = re.search(r'&ELECTRONS.*?/', original_input, re.DOTALL).group(0)
    atomic_species = re.search(r'ATOMIC_SPECIES.*?(?=\n\s*\n)', original_input, re.DOTALL).group(0)
    kpoints = re.search(r'K_POINTS.*?(?=\n\s*\n|$)', original_input, re.DOTALL).group(0)
    
    # Create SCF input with relaxed geometry
    # Clean control section (remove smearing - it belongs in SYSTEM)
    clean_control = control_section.replace("'relax'", "'scf'")
    clean_control = re.sub(r'\s*smearing.*\n', '', clean_control)
    clean_control = re.sub(r'\s*degauss.*\n', '', clean_control)

    scf_input = clean_control + "\n" + system_section + "\n" + electrons_section + "\n"
    scf_input += atomic_species + "\n"
    scf_input += last_positions + "\n"
    
    if last_cell:
        scf_input += last_cell + "\n"
    
    scf_input += kpoints
    
    # Write SCF input file
    scf_filename = f"{system_name}_scf_on_relaxed.in"
    with open(scf_filename, 'w') as f:
        f.write(scf_input)
    
    print(f"Created: {scf_filename}")
    print(f"Use relaxed geometry from: {relax_output_file}")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 extract_geometry.py <relax_output.out> <system_name>")
        print("Example: python3 extract_geometry.py system1_relax.out system1")
        sys.exit(1)
    
    relax_output = sys.argv[1]
    system_name = sys.argv[2]
    
    success = extract_relaxed_geometry(relax_output, system_name)
    sys.exit(0 if success else 1)
