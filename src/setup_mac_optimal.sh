#!/bin/bash
# Setup script for full QE calculations

echo "=== Setting up FULL QE Optimal Workflow ==="

# Check QE installation
if ! command -v pw.x &> /dev/null; then
    echo "ERROR: pw.x not found. Install with: brew install quantum-espresso"
    exit 1
fi

echo "✓ pw.x found: $(which pw.x)"

# Create system directories
for system in system1 system2 system3; do
    mkdir -p $system/tmp_$system
    echo "Created directory: $system/"
done

# Update paths in input files
echo "Updating file paths..."
for file in input_files/*.in; do
    if [ -f "$file" ]; then
        sed -i.bak "s|pseudo_dir = '../../pseudopotentials/'|pseudo_dir = '../pseudopotentials/'|g" "$file"
        echo "Updated: $(basename $file)"
    fi
done

echo ""
echo "System information:"
sysctl -n hw.ncpu | xargs echo "CPU cores:"
sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}' | xargs echo "Total RAM:"

echo ""
echo "Setup complete! Ready for optimal QE workflow."
echo "Run: ./run_optimal_workflow.sh"
