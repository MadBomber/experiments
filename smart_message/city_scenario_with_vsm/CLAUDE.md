# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a SmartMessage City Scenario demonstration that simulates emergency services communication in a city environment. The system uses Redis pub/sub messaging with custom SmartMessage protocol (relative path: `../../lib/smart_message`) and VSM (Vector Symbolic Memory) for AI agent support.

## Architecture

The system consists of multiple Ruby services that communicate via Redis pub/sub:

### Core Services
- **Emergency Dispatch Center (911)** - Routes emergency calls to appropriate departments
- **Police Department** - Responds to crimes, accidents, and silent alarms
- **Fire Department** - Handles fires, medical emergencies, and rescue operations
- **Health Department** - Monitors city health status and broadcasts health checks
- **Houses** - Can trigger fire emergencies
- **Local Bank** - Generates silent alarms
- **Citizens** - Make 911 calls with various emergency scenarios

### Support Components
- **Redis Monitor** - Real-time message traffic visualization
- **Redis Statistics** - Performance metrics dashboard
- **Common Modules** - Shared health monitoring and logging functionality

## Commands

### Running the Demo
```bash
# Start all services in iTerm2 tabs
./start_demo.sh

# Stop all services
./stop_demo.sh

# Run individual services
ruby health_department.rb
ruby police_department.rb
ruby fire_department.rb
ruby emergency_dispatch_center.rb
ruby house.rb "456 Oak Street"
ruby local_bank.rb
ruby citizen.rb auto

# Monitor Redis messages
ruby redis_monitor.rb
ruby redis_stats.rb
```

### Development
```bash
# Ruby version required: 3.x
ruby --version

# Check Redis connection (must be running)
redis-cli ping
```

## Message Flow Architecture

Messages use the SmartMessage protocol with headers containing `from` and `to` fields. Key message types:
- `Emergency911Message` - Citizen to 911 dispatch
- `PoliceDispatchMessage` - 911 to Police
- `FireDispatchMessage` - 911 to Fire
- `FireEmergencyMessage` - Houses to Fire Department
- `SilentAlarmMessage` - Bank to Police
- `HealthCheckMessage` - Health Department broadcasts
- `HealthStatusMessage` - Services report status
- `EmergencyResolvedMessage` - Resolution notifications

## Key Patterns

### Service Structure
All services follow similar patterns:
1. Initialize with `@service_name`
2. Setup message subscriptions
3. Include `Common::HealthMonitor` and `Common::Logger`
4. Implement signal handlers for graceful shutdown
5. Main service loop with error recovery

### Incident Management
Emergency services (Police/Fire) track active incidents with:
- Resource unit assignment based on severity
- Duration-based automatic resolution (10-15 seconds simulation)
- Unit return-to-pool after resolution

### Refactoring Opportunities
See `room_for_improvement.md` for identified patterns that could be extracted into mixins:
- `Common::SignalHandler` - Duplicated signal handling
- `Common::IncidentManager` - Shared Fire/Police incident tracking
- `Common::MessageSetup` - Message header configuration
- `Common::DispatchResponder` - House/Bank dispatch response handling

## Dependencies

- Ruby 3.x
- Redis server (for pub/sub messaging)
- iTerm2 (for multi-tab demo launcher)
- SmartMessage library (`../../lib/smart_message`)
- VSM library (Vector Symbolic Memory for AI agents)
- The goal of this experiment is to create a CityCouncil class in the file city_council.rb which will dynamically create and persis new ruby program to handle missing city services requested in this city scenario
- never leave a user wondering what is going on with the program always give some kind of periodic update to the user.