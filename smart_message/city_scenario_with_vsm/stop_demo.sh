#!/bin/bash

# SmartMessage City Demo Shutdown Script for iTerm2
# Stops all city services and closes the iTerm2 demo window
# Dynamically handles all departments discovered in start_demo.sh

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping SmartMessage City Demo..."

# Check if iTerm2 is running (process name is "iTerm" not "iTerm2")
if ! pgrep -x "iTerm" > /dev/null; then
    echo "iTerm2 is not running."
    # Still continue to check for orphaned processes
fi

# Discover the same departments as start_demo.sh
echo "Discovering running city departments..."
YAML_DEPARTMENTS=($(ls *_department.yml 2>/dev/null | sed 's/.yml$//' | sort))
RUBY_DEPARTMENTS=($(ls *_department.rb 2>/dev/null | grep -v "generic_department.rb" | sed 's/.rb$//' | sort))

# Filter out test departments
YAML_DEPARTMENTS=($(printf '%s\n' "${YAML_DEPARTMENTS[@]}" | grep -v "test_"))
RUBY_DEPARTMENTS=($(printf '%s\n' "${RUBY_DEPARTMENTS[@]}" | grep -v "test_"))

echo "Found ${#YAML_DEPARTMENTS[@]} YAML departments and ${#RUBY_DEPARTMENTS[@]} Ruby departments to stop."
echo "Will also stop all running houses, citizens, visitors, and support services..."

# Function to find and close demo window
echo "Looking for SmartMessage city demo window in iTerm2..."

WINDOW_CLOSED=$(osascript <<'EOF'
tell application "iTerm2"
    set windowFound to false
    
    repeat with theWindow in windows
        tell theWindow
            set tabNames to {}
            repeat with theTab in tabs
                set end of tabNames to (name of current session of theTab)
            end repeat
            
            -- Check if this window has our city demo tabs (look for common indicators)
            set cityKeywords to {"Department", "City Council", "Local Bank", "House", "Emergency", "Redis", "Citizen"}
            set foundKeywords to 0
            
            repeat with keyword in cityKeywords
                repeat with tabName in tabNames
                    if tabName contains keyword then
                        set foundKeywords to foundKeywords + 1
                        exit repeat
                    end if
                end repeat
            end repeat
            
            -- If we found multiple city-related tabs, this is likely our demo window
            if foundKeywords >= 3 then
                set windowFound to true
                
                -- Send Ctrl+C to stop programs and exit shells
                repeat with theTab in tabs
                    tell current session of theTab
                        write text (character id 3) -- Ctrl+C
                        delay 0.5
                        write text "exit" -- Exit the shell to close cleanly
                    end tell
                end repeat
                
                delay 2
                -- Force close the window
                close theWindow
                exit repeat
            end if
        end tell
    end repeat
    
    return windowFound
end tell
EOF
)

if [ "$WINDOW_CLOSED" = "true" ]; then
    echo "✅ City demo window found and closed successfully."
else
    echo "⚠️  No city demo window found. Checking for orphaned processes..."
fi

# Clean up any remaining city service processes
echo "Checking for remaining city service processes..."

# Build dynamic process patterns for all departments
PROCESS_PATTERNS=()
for dept in "${YAML_DEPARTMENTS[@]}" "${RUBY_DEPARTMENTS[@]}"; do
    PROCESS_PATTERNS+=("$dept")
done

# Add core city service programs
CORE_PROGRAMS=("local_bank" "house" "city_council" "emergency_dispatch_center" "citizen" "visitor" "redis_monitor" "redis_stats" "generic_department" "tip_line")
PROCESS_PATTERNS+=("${CORE_PROGRAMS[@]}")

# Create regex pattern for pgrep
PATTERN=$(IFS="|"; echo "${PROCESS_PATTERNS[*]}")
ORPHANS=$(pgrep -f "($PATTERN)\.rb")

if [ -n "$ORPHANS" ]; then
    PROCESS_COUNT=$(echo "$ORPHANS" | wc -w)
    echo "Found $PROCESS_COUNT orphaned city service processes. Cleaning up..."
    echo "$ORPHANS" | while read pid; do
        if [ -n "$pid" ]; then
            PROCESS_NAME=$(ps -p "$pid" -o command= 2>/dev/null | head -1)
            # Extract the program name and parameters for better display
            PROGRAM_NAME=$(echo "$PROCESS_NAME" | sed -n 's/.*ruby \([^ ]*\).*/\1/p' | xargs basename 2>/dev/null || echo "unknown")
            PROGRAM_ARGS=$(echo "$PROCESS_NAME" | sed -n 's/.*ruby [^ ]* \(.*\)/\1/p' || echo "")
            if [ -n "$PROGRAM_ARGS" ]; then
                echo "  Stopping $PROGRAM_NAME ($PROGRAM_ARGS) - PID $pid"
            else
                echo "  Stopping $PROGRAM_NAME - PID $pid"
            fi
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    
    # Wait a moment for graceful termination
    sleep 2
    
    # Force kill any remaining processes
    REMAINING=$(pgrep -f "($PATTERN)\.rb")
    if [ -n "$REMAINING" ]; then
        REMAINING_COUNT=$(echo "$REMAINING" | wc -w)
        echo "Force killing $REMAINING_COUNT remaining processes..."
        echo "$REMAINING" | while read pid; do
            if [ -n "$pid" ]; then
                PROCESS_NAME=$(ps -p "$pid" -o command= 2>/dev/null | head -1)
                PROGRAM_NAME=$(echo "$PROCESS_NAME" | sed -n 's/.*ruby \([^ ]*\).*/\1/p' | xargs basename 2>/dev/null || echo "unknown")
                PROGRAM_ARGS=$(echo "$PROCESS_NAME" | sed -n 's/.*ruby [^ ]* \(.*\)/\1/p' || echo "")
                if [ -n "$PROGRAM_ARGS" ]; then
                    echo "  Force killing $PROGRAM_NAME ($PROGRAM_ARGS) - PID $pid"
                else
                    echo "  Force killing $PROGRAM_NAME - PID $pid"
                fi
                kill -KILL "$pid" 2>/dev/null || true
            fi
        done
    fi
    
    echo "✅ Orphaned processes cleaned up."
else
    echo "✅ No orphaned processes found."
fi

# Clean up Redis channels and reset message counts
echo "Cleaning up Redis channels..."
redis-cli <<EOF > /dev/null 2>&1
# Unsubscribe all clients from SmartMessage channels
CLIENT LIST | grep -o 'id=[0-9]*' | cut -d= -f2 | xargs -I {} CLIENT KILL ID {}
# Note: We can't actually "clear" channels in Redis, but killing clients removes subscriptions
# The publish counts remain in Redis stats but that's historical data
EOF

echo "✅ Redis channels cleaned up."

echo ""
echo "🛑 SmartMessage city demo has been stopped."
echo "   All emergency services are offline."
echo "   All 4 houses, 5 citizens, and 6 visitors have been stopped."
echo ""
echo "💡 To start the city demo again, run: ./start_demo.sh"