#!/usr/bin/env bash
# flatten_json_keys.sh
# brew install gron

# Check if a directory is provided as an argument
if [ $# -eq 0 ]; then
    echo "Please provide a directory path as an argument."
    exit 1
fi

# Directory containing JSON files
json_dir="$1"

# Check if the directory exists
if [ ! -d "$json_dir" ]; then
    echo "The specified directory does not exist."
    exit 1
fi

# Process each JSON file in the directory
for json_file in "$json_dir"/*.json; do
    # Check if there are any JSON files
    if [ ! -e "$json_file" ]; then
        echo "No JSON files found in the specified directory."
        exit 1
    fi

    # Get the base name of the JSON file
    base_name=$(basename "$json_file" .json)
    
    # Create the output text file name
    output_file="$json_dir/${base_name}.txt"
    
    # Use gron to flatten the JSON and save to the text file
    gron "$json_file" > "$output_file"
    
    echo "Processed: $json_file -> $output_file"
done

echo "All JSON files have been processed."
