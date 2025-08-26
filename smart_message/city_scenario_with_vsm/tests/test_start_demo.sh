#!/bin/bash

# Test script for start_demo.sh - creates just first few tabs to verify functionality

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Testing start_demo.sh with limited departments..."

# Discover departments
YAML_DEPARTMENTS=($(ls *_department.yml 2>/dev/null | sed 's/.yml$//' | sort))
RUBY_DEPARTMENTS=($(ls *_department.rb 2>/dev/null | grep -v "generic_department.rb" | sed 's/.rb$//' | sort))

# Filter out test departments
YAML_DEPARTMENTS=($(printf '%s\n' "${YAML_DEPARTMENTS[@]}" | grep -v "test_"))
RUBY_DEPARTMENTS=($(printf '%s\n' "${RUBY_DEPARTMENTS[@]}" | grep -v "test_"))

echo "Found ${#YAML_DEPARTMENTS[@]} YAML departments"
echo "Found ${#RUBY_DEPARTMENTS[@]} Ruby departments"

# Test creating just first few tabs
cat <<EOF | osascript
tell application "iTerm2"
    activate
    
    -- Create new window
    set newWindow to (create window with default profile)
    
    -- Tab 1: City Council
    tell current session of current tab of newWindow
        delay 0.5
        write text "cd '$DEMO_DIR'"
        write text "clear"
        write text "echo 'Testing: City Council Tab'"
    end tell
end tell
EOF

# Test creating one YAML department tab
if [ ${#YAML_DEPARTMENTS[@]} -gt 0 ]; then
    dept="${YAML_DEPARTMENTS[0]}"
    display_name=$(echo "$dept" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
    echo "Testing YAML department: $dept -> $display_name"
    
    cat <<EOF | osascript
    tell application "iTerm2"
        tell current window
            set newTab to (create tab with default profile)
            tell current session of newTab
                delay 0.5
                write text "cd '$DEMO_DIR'"
                write text "clear"
                write text "echo 'Testing: $display_name'"
                write text "echo 'Command would be: ruby generic_department.rb $dept'"
            end tell
        end tell
    end tell
EOF
fi

# Test creating one Ruby department tab
if [ ${#RUBY_DEPARTMENTS[@]} -gt 0 ]; then
    dept="${RUBY_DEPARTMENTS[0]}"
    display_name=$(echo "$dept" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
    echo "Testing Ruby department: $dept -> $display_name"
    
    cat <<EOF | osascript
    tell application "iTerm2"
        tell current window
            set newTab to (create tab with default profile)
            tell current session of newTab
                delay 0.5
                write text "cd '$DEMO_DIR'"
                write text "clear"
                write text "echo 'Testing: $display_name'"
                write text "echo 'Command would be: ruby $dept.rb'"
            end tell
        end tell
    end tell
EOF
fi

echo "✅ Test completed - check iTerm2 for 3 test tabs"