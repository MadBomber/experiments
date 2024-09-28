#!/usr/bin/env bash
# extract_houses.sh

# Input file
input_file="dataset.txt"

# Output file prefix
output_prefix="house_"

# Initialize sequence number
seq_num=1

# Read each line from the input file
while IFS= read -r line; do
    # Check if the line is not empty
    if [[ -n "$line" ]]; then
        # Format the sequence number to be zero-filled (2 digits)
        formatted_num=$(printf "%02d" "$seq_num")
        
        # Create the output file name
        output_file="${output_prefix}${formatted_num}.json"
        
        # Write the line to the output file
        echo "$line" > "$output_file"
        
        # Increment the sequence number
        ((seq_num++))
    fi
done < "$input_file"

