#!/bin/bash

echo "Testing department discovery logic..."
echo

# Discover all department YAML files and legacy Ruby files
echo "Discovering city departments..."
YAML_DEPARTMENTS=($(ls *_department.yml 2>/dev/null | sed 's/.yml$//' | sort))
RUBY_DEPARTMENTS=($(ls *_department.rb 2>/dev/null | grep -v "generic_department.rb" | sed 's/.rb$//' | sort))

# Filter out test departments
YAML_DEPARTMENTS=($(printf '%s\n' "${YAML_DEPARTMENTS[@]}" | grep -v "test_"))
RUBY_DEPARTMENTS=($(printf '%s\n' "${RUBY_DEPARTMENTS[@]}" | grep -v "test_"))

TOTAL_DEPARTMENTS=$((${#YAML_DEPARTMENTS[@]} + ${#RUBY_DEPARTMENTS[@]}))

echo "Found ${#YAML_DEPARTMENTS[@]} YAML-configured departments:"
for dept in "${YAML_DEPARTMENTS[@]}"; do
    echo "  - $dept (generic_department.rb)"
done

if [ ${#RUBY_DEPARTMENTS[@]} -gt 0 ]; then
    echo "Found ${#RUBY_DEPARTMENTS[@]} legacy Ruby departments:"
    for dept in "${RUBY_DEPARTMENTS[@]}"; do
        echo "  - $dept (native Ruby)"
    done
fi

echo
echo "Total departments: $TOTAL_DEPARTMENTS"
echo

# Test command generation for first few YAML departments
echo "Sample launch commands for first 3 YAML departments:"
for dept in "${YAML_DEPARTMENTS[@]:0:3}"; do
    display_name=$(echo "$dept" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
    echo "  $dept -> ruby generic_department.rb $dept"
    echo "    Display: $display_name"
done