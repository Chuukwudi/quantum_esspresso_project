#!/bin/bash
# Automated workflow: relaxation → extract geometry → SCF on relaxed

run_full_workflow() {
    local system=$1
    echo "=== Running full workflow for $system ==="
    
    cd $system
    
    # Step 1: Run relaxation
    echo "Step 1: Running relaxation..."
    export OMP_NUM_THREADS=10
    time mpirun -np 10 pw.x < ../input_files/${system}_relax.in > ${system}_relax.out 2>&1
    
    # Check if relaxation completed
    if grep -q "JOB DONE" ${system}_relax.out; then
        echo "✓ Relaxation completed successfully"
    else
        echo "⚠ Relaxation may not have completed fully"
        echo "Checking final forces..."
        grep "Total force" ${system}_relax.out | tail -3
    fi
    
    # Step 2: Extract relaxed geometry
    echo "Step 2: Extracting relaxed geometry..."
    if [ -f "${system}_relax.out" ]; then
        python3 ../scripts/extract_geometry.py ${system}_relax.out $system
    else
        echo "✗ Relaxation output file not found"
    fi
    
    # Step 3: Run SCF on relaxed geometry
    if [ -f "${system}_scf_on_relaxed.in" ]; then
        echo "Step 3: Running SCF on relaxed geometry..."
        time mpirun -np 10 pw.x < ${system}_scf_on_relaxed.in > ${system}_scf_on_relaxed.out 2>&1

        if grep -q "JOB DONE" ${system}_scf_on_relaxed.out; then
            echo "✓ Final SCF completed successfully"
            echo "Final energy:"
            grep "! *total energy" ${system}_scf_on_relaxed.out | tail -1
        else
            echo "⚠ Final SCF had issues"
        fi
    else
        echo "✗ Could not create SCF input from relaxed geometry"
    fi
    
    cd ..
    echo "=== $system workflow complete ==="
    echo ""
}

# Main execution
echo "=== STANFORD QE OPTIMAL WORKFLOW ==="
echo "This script runs: relaxation → extract geometry → SCF on relaxed"
echo ""

# Run all systems
for system in system2 system3; do
    if [ -d "$system" ]; then
        run_full_workflow $system
    else
        echo "Skipping $system - directory not found"
    fi
done

echo "=== ALL CALCULATIONS COMPLETE ==="
echo "Creating results package..."

# Package all results
tar -czf stanford_qe_optimal_results.tar.gz system*/*.out $(find system* -name "*_scf_on_relaxed.in" 2>/dev/null || echo "")

echo "Results packaged as: stanford_qe_optimal_results.tar.gz"
echo "Send this file back to your collaborator!"
