#!/usr/bin/env bash
# Parallel LaTeX Build Script (bash equivalent of build-parallel.ps1)
echo "=== Parallel LaTeX Build Script ==="

# Find all TeX files in main directory
mapfile -t texFiles < <(find ./main -maxdepth 1 -name "*.tex" | sort)
echo "Found ${#texFiles[@]} TeX files to compile in parallel..."

# First compilation pass (parallel)
pids=()
for file in "${texFiles[@]}"; do
    echo "Starting first compilation pass of $(basename "$file")..."
    lualatex -interaction=nonstopmode -output-directory=. "$file" &
    pids+=($!)
done

# Wait for first pass
echo "Waiting for first compilation pass to complete..."
for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
        echo "First pass completed for $(basename "${texFiles[$i]}")"
    else
        echo "First pass FAILED for $(basename "${texFiles[$i]}")"
    fi
done

# Second compilation pass (parallel)
pids2=()
for file in "${texFiles[@]}"; do
    echo "Starting second compilation pass of $(basename "$file")..."
    lualatex -interaction=nonstopmode -output-directory=. "$file" &
    pids2+=($!)
done

# Wait for second pass
echo "Waiting for second compilation pass to complete..."
for i in "${!pids2[@]}"; do
    if wait "${pids2[$i]}"; then
        echo "Successfully compiled $(basename "${texFiles[$i]}") (2 passes)"
    else
        echo "FAILED second pass for $(basename "${texFiles[$i]}")"
    fi
done

# Move PDF files to main/pdfs directory
echo "Moving PDF files to main/pdfs directory..."
mkdir -p ./main/pdfs

for pdf in ./*.pdf; do
    base=$(basename "$pdf")
    if [[ "$base" == main_* || "$base" == presentation* || "$base" == print* ]]; then
        mv "$pdf" ./main/pdfs/
        echo "Moved $base to main/pdfs/"
    fi
done

# Clean up temporary files
echo "Cleaning up temporary files..."
find . -maxdepth 1 \( \
    -name "*.aux" -o -name "*.log" -o -name "*.nav" -o -name "*.out" \
    -o -name "*.snm" -o -name "*.toc" -o -name "*.atfi" -o -name "*.fls" \
    -o -name "*.fdb_latexmk" -o -name "*.synctex.gz" -o -name "*.bbl" -o -name "*.blg" \
\) -delete

echo "Cleanup completed!"
echo "=== Build process finished ==="
