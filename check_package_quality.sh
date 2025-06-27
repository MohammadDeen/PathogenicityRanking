#!/bin/bash

# Script to test package quality before merging to main
echo "=== PathogenicityRanking Package Quality Check ==="

# Check if R is available
if ! command -v R &> /dev/null; then
    echo "❌ R is not installed or not in PATH"
    exit 1
fi

echo "✅ R is available"

# Run R CMD check
echo "Running R CMD check..."
R CMD build .
if [ $? -eq 0 ]; then
    echo "✅ Package builds successfully"
else
    echo "❌ Package build failed"
    exit 1
fi

# Find the built package
PKG_FILE=$(ls PathogenicityRanking_*.tar.gz | head -1)
if [ -z "$PKG_FILE" ]; then
    echo "❌ Built package not found"
    exit 1
fi

echo "Checking package: $PKG_FILE"
R CMD check "$PKG_FILE" --as-cran

if [ $? -eq 0 ]; then
    echo "✅ R CMD check passed"
else
    echo "❌ R CMD check failed"
    echo "Please fix all errors and warnings before merging"
    exit 1
fi

echo "🎉 Package quality check completed successfully!"
echo "Ready for merge to main branch"
