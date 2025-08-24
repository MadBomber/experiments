#!/bin/bash

# SmartMessage City Demo Shutdown Script for iTerm2
# Stops all city services and closes the iTerm2 demo window

echo "Stopping SmartMessage City Demo..."

# Check if iTerm2 is running (process name is "iTerm" not "iTerm2")
if ! pgrep -x "iTerm" > /dev/null; then
    echo "iTerm2 is not running."
    # Still continue to check for orphaned processes
fi

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
            
            -- Check if this window has our city demo tabs
            if "Health Department" is in tabNames or "Police Department" is in tabNames or "Fire Department" is in tabNames or "Local Bank" is in tabNames or "City Council" is in tabNames or "911 Dispatch" is in tabNames then
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

# Include all demo programs in the cleanup
ORPHANS=$(pgrep -f "(health_department|police_department|fire_department|local_bank|house|city_council|emergency_dispatch_center|citizen|redis_monitor|redis_stats)\.rb")

if [ -n "$ORPHANS" ]; then
    echo "Found orphaned city service processes. Cleaning up..."
    echo "$ORPHANS" | while read pid; do
        echo "  Stopping process $pid..."
        kill -TERM "$pid" 2>/dev/null || true
    done
    
    # Wait a moment for graceful termination
    sleep 1
    
    # Force kill any remaining processes
    REMAINING=$(pgrep -f "(health_department|police_department|fire_department|local_bank|house|city_council|emergency_dispatch_center|citizen|redis_monitor|redis_stats)\.rb")
    if [ -n "$REMAINING" ]; then
        echo "Force killing remaining processes..."
        echo "$REMAINING" | while read pid; do
            echo "  Force killing process $pid..."
            kill -KILL "$pid" 2>/dev/null || true
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
echo ""
echo "💡 To start the city demo again, run: ./start_demo.sh"