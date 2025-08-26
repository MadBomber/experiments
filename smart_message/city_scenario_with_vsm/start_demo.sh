#!/bin/bash

# SmartMessage City Demo Launcher for iTerm2
# Creates a new iTerm2 window with separate tabs for each city service
# Dynamically discovers and launches all departments based on YAML configs

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Removing old log files..."
rm -f "$DEMO_DIR/log/"*.log

# Check if iTerm2 is available
if ! ls /Applications/iTerm.app &>/dev/null; then
    echo "Error: iTerm2 is not installed."
    echo "Please install iTerm2 from https://iterm2.com/"
    exit 1
fi

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

echo "Starting SmartMessage City Demo in iTerm2..."

# Create a single comprehensive AppleScript
cat <<EOF | osascript
tell application "iTerm2"
    activate

    -- Create new window
    set newWindow to (create window with default profile)

    -- Tab 1: City Council (already created with the window)
    tell current session of current tab of newWindow
        delay 0.5
        write text "cd '$DEMO_DIR'"
        write text "clear"
        write text "echo 'Starting City Council (Department Generator)...'"
        write text "ruby city_council.rb"
    end tell
end tell
EOF

# Generate the department tabs dynamically
for dept in "${YAML_DEPARTMENTS[@]}"; do
    display_name=$(echo "$dept" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
    cat <<EOF | osascript
    tell application "iTerm2"
        tell current window
            set newTab to (create tab with default profile)
            tell current session of newTab
                delay 0.5
                write text "cd '$DEMO_DIR'"
                write text "clear"
                write text "echo 'Starting $display_name...'"
                write text "ruby generic_department.rb $dept"
            end tell
        end tell
    end tell
EOF
done

# Generate AppleScript for legacy Ruby departments
for dept in "${RUBY_DEPARTMENTS[@]}"; do
    display_name=$(echo "$dept" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
    cat <<EOF | osascript
    tell application "iTerm2"
        tell current window
            set newTab to (create tab with default profile)
            tell current session of newTab
                delay 0.5
                write text "cd '$DEMO_DIR'"
                write text "clear"
                write text "echo 'Starting $display_name...'"
                write text "ruby $dept.rb"
            end tell
        end tell
    end tell
EOF
done

# Add supporting services tabs
cat <<EOF | osascript
tell application "iTerm2"
    tell current window
        -- Local Bank
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Local Bank...'"
            write text "ruby local_bank.rb"
        end tell

        -- House #1
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting House #1...'"
            write text "ruby house.rb '456 Oak Street'"
        end tell

        -- House #2
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting House #2...'"
            write text "ruby house.rb '789 Pine Lane'"
        end tell

        -- House #3
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting House #3...'"
            write text "ruby house.rb '321 Elm Drive'"
        end tell

        -- House #4
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting House #4...'"
            write text "ruby house.rb '654 Maple Road'"
        end tell

        -- Emergency Dispatch (911)
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Emergency Dispatch Center (911)...'"
            write text "ruby emergency_dispatch_center.rb"
        end tell

        -- Citizen #1
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Citizen #1 - John Smith...'"
            write text "sleep 3; ruby citizen.rb 'John Smith' auto"
        end tell

        -- Citizen #2
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Citizen #2 - Mary Johnson...'"
            write text "sleep 4; ruby citizen.rb 'Mary Johnson' auto"
        end tell

        -- Citizen #3
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Citizen #3 - Robert Williams...'"
            write text "sleep 5; ruby citizen.rb 'Robert Williams' auto"
        end tell

        -- Citizen #4
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Citizen #4 - Patricia Brown...'"
            write text "sleep 6; ruby citizen.rb 'Patricia Brown' auto"
        end tell

        -- Citizen #5
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Citizen #5 - Michael Davis...'"
            write text "sleep 7; ruby citizen.rb 'Michael Davis' auto"
        end tell

        -- Visitor #1
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Visitor #1 from Chicago...'"
            write text "sleep 8; ruby visitor.rb 'Chicago'"
        end tell

        -- Visitor #2
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Visitor #2 from Boston...'"
            write text "sleep 9; ruby visitor.rb 'Boston'"
        end tell

        -- Visitor #3
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Visitor #3 from Seattle...'"
            write text "sleep 10; ruby visitor.rb 'Seattle'"
        end tell

        -- Visitor #4
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Visitor #4 from Denver...'"
            write text "sleep 11; ruby visitor.rb 'Denver'"
        end tell

        -- Visitor #5
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Visitor #5 from Atlanta...'"
            write text "sleep 12; ruby visitor.rb 'Atlanta'"
        end tell

        -- Visitor #6
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Visitor #6 from Phoenix...'"
            write text "sleep 13; ruby visitor.rb 'Phoenix'"
        end tell

        -- Redis Monitor
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Redis Message Monitor...'"
            write text "ruby redis_monitor.rb"
        end tell

        -- Redis Statistics
        set newTab to (create tab with default profile)
        tell current session of newTab
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Redis Statistics Dashboard...'"
            write text "ruby redis_stats.rb"
        end tell

        -- Switch back to first tab
        select (first tab)
    end tell
end tell
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SmartMessage City Demo launched successfully!"
    echo ""
    echo "📊 Demo Status:"
    echo "   • City Council: 1 tab"
    echo "   • YAML Departments: ${#YAML_DEPARTMENTS[@]} tabs"
    echo "   • Legacy Departments: ${#RUBY_DEPARTMENTS[@]} tabs"
    echo "   • Houses: 4 tabs"
    echo "   • Citizens: 5 tabs"
    echo "   • Visitors: 6 tabs"
    echo "   • Support Services: 4 tabs (Bank, 911, Redis Monitor, Redis Stats)"
    echo "   • Total Tabs: $((1 + ${#YAML_DEPARTMENTS[@]} + ${#RUBY_DEPARTMENTS[@]} + 4 + 5 + 6 + 4))"
    echo ""
    echo "🏛️ Departments running:"
    for dept in "${YAML_DEPARTMENTS[@]}"; do
        echo "   • $dept (YAML config)"
    done
    for dept in "${RUBY_DEPARTMENTS[@]}"; do
        echo "   • $dept (Ruby native)"
    done
    echo ""
    ruby tip_line.rb
    echo ""
    echo "💡 Multiple Instance Examples:"
    echo ""
    echo "   Run multiple houses with different addresses:"
    echo "     ruby house.rb \"123 Main Street\""
    echo "     ruby house.rb \"456 Oak Avenue\""
    echo "     ruby house.rb \"789 Pine Lane\""
    echo ""
    echo "   Run multiple visitors from different home towns:"
    echo "     ruby visitor.rb \"Chicago\""
    echo "     ruby visitor.rb \"Boston\""
    echo "     ruby visitor.rb \"Seattle\""
    echo ""
    echo "   Run multiple citizens with different names:"
    echo "     ruby citizen.rb \"John Smith\" auto"
    echo "     ruby citizen.rb \"Mary Johnson\" auto"
    echo "     ruby citizen.rb \"Robert Brown\" auto"
    echo ""
    echo "   Single observation mode for visitors:"
    echo "     ruby visitor.rb \"Denver\" --once"
    echo ""
else
    echo "😔 Failed to start demo. Please check that iTerm2 is installed and running."
    exit 1
fi
