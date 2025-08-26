#!/bin/bash

echo "Testing stop_demo.sh discovery logic..."

# Use same discovery logic as stop_demo.sh
YAML_DEPARTMENTS=($(ls *_department.yml 2>/dev/null | sed 's/.yml$//' | sort))
RUBY_DEPARTMENTS=($(ls *_department.rb 2>/dev/null | grep -v "generic_department.rb" | sed 's/.rb$//' | sort))

# Filter out test departments
YAML_DEPARTMENTS=($(printf '%s\n' "${YAML_DEPARTMENTS[@]}" | grep -v "test_"))
RUBY_DEPARTMENTS=($(printf '%s\n' "${RUBY_DEPARTMENTS[@]}" | grep -v "test_"))

echo "Found ${#YAML_DEPARTMENTS[@]} YAML departments and ${#RUBY_DEPARTMENTS[@]} Ruby departments to stop."

# Build dynamic process patterns for all departments
PROCESS_PATTERNS=()
for dept in "${YAML_DEPARTMENTS[@]}" "${RUBY_DEPARTMENTS[@]}"; do
    PROCESS_PATTERNS+=("$dept")
done

# Add core city service programs
CORE_PROGRAMS=("local_bank" "house" "city_council" "emergency_dispatch_center" "citizen" "redis_monitor" "redis_stats" "generic_department" "tip_line")
PROCESS_PATTERNS+=("${CORE_PROGRAMS[@]}")

# Create regex pattern for pgrep
PATTERN=$(IFS="|"; echo "${PROCESS_PATTERNS[*]}")

echo "Sample departments:"
echo "  YAML: ${YAML_DEPARTMENTS[@]:0:3}"
echo "  Ruby: ${RUBY_DEPARTMENTS[@]}"
echo 
echo "Total process patterns: ${#PROCESS_PATTERNS[@]}"
echo "Pattern (first 150 chars): ${PATTERN:0:150}..."
echo
echo "✅ Stop logic test completed successfully"