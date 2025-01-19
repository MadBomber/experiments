#!/usr/bin/env bash
# scripts/extract_block_references.sh
# Gets the line cross-reference to blocks
#
# TODO: Replace use `ag` with `grep`
#
# CAUTION:  This is _NOT_ a generic script
#           It is crafted for the test document

# Function to display usage information
usage() {
    echo "Usage: $0 <input_file.txt> <output_directory>"
    echo
    echo "Parameters:"
    echo "  input_file.txt   - Path to the input text file (must exist and have .txt extension)"
    echo "  output_directory - Path to the output directory (must exist)"
    echo
    echo "Example:"
    echo "  $0 /path/to/input.txt /path/to/output/directory"
    exit 1
}

# Check if correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of arguments."
    usage
fi

# Assign arguments to variables
input_file="$1"
output_directory="$2"

# Validate input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' does not exist."
    usage
fi

# Check if input file has .txt extension
if [[ "$input_file" != *.txt ]]; then
    echo "Error: Input file '$input_file' must have a .txt extension."
    usage
fi

# Validate output directory exists
if [ ! -d "$output_directory" ]; then
    echo "Error: Output directory '$output_directory' does not exist."
    usage
fi

# Page number are prefixed by the PART number
grep -n '^\(I-\|II-\|III-\|IV-\)' $input_file >$output_directory/page_numbers.txt

##########################################################
## extract the major blocks
## FYI: PART I hierarchie is PART > CHAPTER > SECTION
##      The other parts are PART > SECTION > CHAPTER

unset AGOPTS

ag PART $input_file >$output_directory/part.txt
ag CHAPTER $input_file >$output_directory/chapter.txt
ag SECTION $input_file >$output_directory/section.txt

# Each PART has its own set of appendicies
ag APPENDIX $input_file >$output_directory/appendix.txt

##########################################################
## extract the sub-blocks

# Some sub-blocks tstart with a (
grep -n "^[\(]" $input_file >$output_directory/parans.txt

# Some sub-blocks tstart digits
grep -n '^[0-9]\+\.' $input_file >$output_directory/numbers.txt

# Some sub-blocks start with [
grep -n '^[\[]' $input_file >$output_directory/squares.txt

# TOC blocks
grep -n '^CONTENTS' $input_file >$output_directory/contents.txt

# Page numbers associated with TOC
# grep '\-[ivx]\+$' $output_directory/page_numbers.txt >$output_directory/toc_pages.txt

###########################################
## Put it all together in one numerically
## sorted file

cd $output_directory
cat *.txt | sort -n > citations_raw.srt
