#!/bin/bash

# SmartMessage City Demo Launcher for iTerm2
# Creates a new iTerm2 window with separate tabs for each city service

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Removing old log files..."
rm -f "$DEMO_DIR/log/"*.log

# Check if iTerm2 is available
if ! ls /Applications/iTerm.app &>/dev/null; then
    echo "Error: iTerm2 is not installed."
    echo "Please install iTerm2 from https://iterm2.com/"
    exit 1
fi

echo "Starting SmartMessage City Demo in iTerm2..."

# Create the iTerm2 window and tabs using AppleScript
osascript <<EOF
tell application "iTerm2"
    activate
    
    -- Create new window
    set newWindow to (create window with default profile)
    
    -- Tab 1: City Council (already created)
    tell current session of current tab of newWindow
        set name to "city_council"
        delay 0.5
        write text "cd '$DEMO_DIR'"
        write text "clear"
        write text "echo 'Starting City Council (Department Generator)...'"
        write text "ruby city_council.rb; exit"
    end tell
    
    -- Tab 2: Police Department
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "police_department"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Police Department...'"
            write text "ruby police_department.rb; exit"
        end tell
    end tell
    
    -- Tab 3: Fire Department
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "fire_department"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Fire Department...'"
            write text "ruby fire_department.rb; exit"
        end tell
    end tell
    
    -- Tab 4: Local Bank
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "local_bank"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Local Bank...'"
            write text "ruby local_bank.rb; exit"
        end tell
    end tell
    
    -- Tab 5: House #1
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "house_1"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting House #1...'"
            write text "ruby house.rb '456 Oak Street'; exit"
        end tell
    end tell
    
    -- Tab 6: House #2
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "house_2"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting House #2...'"
            write text "ruby house.rb '789 Pine Lane'; exit"
        end tell
    end tell
    
    -- Tab 7: Health Department
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "health_department"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Health Department...'"
            write text "ruby health_department.rb; exit"
        end tell
    end tell
    
    -- Tab 8: Emergency Dispatch (911)
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "emergency_dispatch_center"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Emergency Dispatch Center (911)...'"
            write text "ruby emergency_dispatch_center.rb; exit"
        end tell
    end tell
    
    -- Tab 9: Citizen Caller
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "citizen"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Citizen 911 Caller...'"
            write text "sleep 3; ruby citizen.rb auto; exit"
        end tell
    end tell
    
    -- Tab 10: Redis Monitor
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "redis_monitor"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Redis Message Monitor...'"
            write text "ruby redis_monitor.rb; exit"
        end tell
    end tell
    
    -- Tab 11: Redis Statistics
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "redis_stats"
            delay 0.5
            write text "cd '$DEMO_DIR'"
            write text "clear"
            write text "echo 'Starting Redis Statistics Dashboard...'"
            write text "ruby redis_stats.rb; exit"
        end tell
    end tell
    
    -- Switch back to first tab
    tell newWindow
        select (first tab)
    end tell
    
end tell
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ City Demo started successfully in iTerm2!"
    echo ""
    echo "🏛️ Tab 1: City Council - dynamically creates new departments"
    echo "🚔 Tab 2: Police Department - responds to alarms & 911 calls"
    echo "🚒 Tab 3: Fire Department - responds to fires & 911 emergencies"
    echo "🏦 Tab 4: Local Bank - triggers occasional alarms"
    echo "🏠 Tab 5: House #1 - 456 Oak Street"
    echo "🏠 Tab 6: House #2 - 789 Pine Lane"
    echo "🏥 Tab 7: Health Department - monitors all city services"
    echo "📞 Tab 8: 911 Dispatch - emergency call routing center"
    echo "👤 Tab 9: Citizen - makes 911 calls automatically"
    echo "🔍 Tab 10: Redis Monitor - real-time message traffic"
    echo "📊 Tab 11: Redis Statistics - performance dashboard"
    echo ""
    echo "📱 Use Cmd+1,2,3,4,5,6,7,8,9,0 to switch between tabs"
    echo "🛑 Run ./stop_demo.sh to stop all services"
    echo ""
    echo "🏛️ Watch Tab 1 for dynamic department creation!"
    echo "🌟 Watch Tab 7 for colored health status updates!"
    echo "📞 Watch Tab 8 for 911 dispatch routing & Tab 9 for citizen emergencies!"
    echo "🔍 Check Tab 10 for real-time message traffic & Tab 11 for Redis stats!"
else
    echo "😔 Failed to start demo. Please check that iTerm2 is installed and running."
    exit 1
fi