#!/bin/bash

# de_doge.sh - Remove consolidated files and restore doged files

echo "Starting de_doge process..."

# First, delete .yml files that contain "consolidation_info:" entry
echo "Checking for .yml files with consolidation_info..."
for file in *.yml; do
    if [[ -f "$file" ]] && grep -q "consolidation_info:" "$file"; then
        echo "Deleting consolidated file: $file"
        rm "$file"
    fi
done

# Next, rename .yml.doged files by removing the .doged extension
echo "Restoring .doged files..."
for file in *.yml.doged; do
    if [[ -f "$file" ]]; then
        new_name="${file%.doged}"
        echo "Renaming $file -> $new_name"
        mv "$file" "$new_name"
    fi
done

echo "De_doge process complete!"