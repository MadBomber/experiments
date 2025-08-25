# CityCouncil - Dynamic City Service Generation

## Overview
The CityCouncil class experiment aims to create a self-extending city simulation that can dynamically generate and persist new Ruby programs to handle missing city services as they are requested.

## How VSM Can Be Used in CityCouncil for Dynamic City Service Creation

Based on analysis of the VSM library, here's how it could be integrated into a CityCouncil class to dynamically create and persist new city service programs:

### VSM Architecture Overview

VSM (Viable Systems Model) provides a **capsule-based architecture** with five core systems:
1. **Operations** - Executes tools/skills (the actual work)
2. **Coordination** - Manages message flow and scheduling
3. **Intelligence** - Makes planning/decisions (can integrate LLMs)
4. **Governance** - Enforces policies and safety rules
5. **Identity** - Defines purpose and invariants

### CityCouncil Integration Approach

The CityCouncil class would leverage VSM to:

#### 1. **Dynamic Service Creation as Tool Capsules**
Each city service (Police, Fire, Health, etc.) can be modeled as a VSM ToolCapsule that:
- Has its own message handling logic via `run(args)`
- Declares its capabilities through JSON Schema
- Can be dynamically instantiated and added to Operations

#### 2. **AI-Powered Service Generation**
The CityCouncil's Intelligence component would:
- Use LLM integration (via RubyLLM) to understand requests for missing services
- Generate Ruby code for new service classes based on patterns from existing services
- Create appropriate message types for inter-service communication

#### 3. **Service Template System**
```ruby
class CityServiceTemplate < VSM::ToolCapsule
  # Base template for all city services
  tool_schema({ 
    type: "object",
    properties: {
      message_type: { type: "string" },
      payload: { type: "object" }
    }
  })
  
  def run(args)
    # Default message handling
  end
end
```

#### 4. **Dynamic Code Generation Flow**
```ruby
class CityCouncilIntelligence < VSM::Intelligence
  def handle(message, bus:, **)
    if message.payload.include?("need") || message.payload.include?("missing")
      # 1. Analyze request using LLM
      # 2. Generate service specification
      # 3. Create Ruby code from templates
      # 4. Persist to file system
      # 5. Load and register new service
      generate_city_service(message)
    end
  end
  
  def generate_city_service(request)
    # Use LLM to understand service requirements
    # Generate Ruby class based on existing patterns
    # Write to city_services/ directory
    # Dynamically load and register with VSM
  end
end
```

#### 5. **Persistence Strategy**
- New departments saved as `*_department.rb` files in the current directory
- Department names must follow the pattern: `{service}_department.rb`
- Message definitions saved in `messages/` directory following existing patterns
- Each department file must set `@service_name` to match its filename (without .rb)

#### 6. **VSM Capsule Structure for CityCouncil**
```ruby
city_council = VSM::DSL.define(:city_council) do
  identity klass: VSM::Identity, 
           args: { 
             identity: "city_council",
             invariants: ["must serve citizens", "create needed services"]
           }
  
  governance klass: CityGovernance  # Validates new services
  coordination klass: VSM::Coordination
  intelligence klass: CityCouncilIntelligence  # LLM-powered
  
  operations do
    # Existing services loaded here
    capsule :police, klass: PoliceDepartment
    capsule :fire, klass: FireDepartment
    # Dynamically add new services at runtime
  end
end
```

#### 7. **Key Benefits of VSM Integration**

- **Recursive Architecture**: New services can themselves contain sub-capsules for complex functionality
- **Async Message Bus**: Non-blocking communication between all services
- **Tool Descriptors**: Auto-generate API descriptions for new services
- **Observability**: Built-in JSONL logging of all service interactions
- **Governance Layer**: Ensure new services meet safety/policy requirements
- **Execution Modes**: Services can run in fibers (I/O) or threads (CPU-intensive)

#### 8. **Dynamic Service Registration**
```ruby
def register_new_service(service_class)
  # Add to VSM operations at runtime
  city_council.children[service_class.tool_name] = service_class.new
  # Update message routing
  update_message_subscriptions(service_class)
end
```

### Example: Creating a "Traffic Management" Department

When CityCouncil receives "We need traffic management", it would:
1. Use Intelligence (LLM) to understand the requirement
2. Generate `traffic_management_department.rb` following existing department patterns
3. Set `@service_name = 'traffic_management_department'` in the generated code
4. Create message types in `messages/`: `traffic_alert_message.rb`, `signal_control_message.rb`
5. Write files to disk following the naming convention
6. The new department can be discovered by any service scanning for `*_department.rb`
7. Load and register the new service with VSM
8. The service immediately starts handling traffic-related messages

This approach combines VSM's structured agent architecture with dynamic Ruby metaprogramming and AI-powered code generation to create a self-extending city simulation.

## Implementation Notes

### Current Architecture
- Existing services use SmartMessage library for pub/sub via Redis
- Services follow common patterns (see `room_for_improvement.md`)
- Each service has signal handlers, health monitoring, and logging
- **Existing Departments**: `police_department.rb`, `fire_department.rb`, `health_department.rb`

### Service Discovery Mechanism
Programs like `city_council.rb` and `emergency_dispatch_center.rb` should discover available departments by:
1. **File-based Discovery**: Scan the directory for `*_department.rb` files
2. **Naming Convention**: Each department's `@service_name` must match its filename
   - `fire_department.rb` → `@service_name = 'fire_department'`
   - `police_department.rb` → `@service_name = 'police_department'`
   - `health_department.rb` → `@service_name = 'health_department'`

```ruby
# Service Discovery Pattern
def discover_departments
  Dir.glob('*_department.rb').map do |file|
    File.basename(file, '.rb')  # Returns: fire_department, police_department, etc.
  end
end

# Dynamic Loading Pattern
def load_department(department_name)
  require_relative department_name
  # Service will self-register with @service_name matching filename
end
```

### Integration Considerations
- VSM could wrap existing SmartMessage communication
- Existing services could be refactored as VSM ToolCapsules
- CityCouncil would act as the parent capsule orchestrating all city services
- New departments generated by CityCouncil must follow the `*_department.rb` naming pattern

## Implementation Status

### Completed Components

#### 1. **CityCouncil System** - **NEW VSM-Compliant Modular Architecture**

**🏗️ Modular File Structure:**
```
city_council.rb                    # Entry point and module namespace (55 lines)
city_council/
  ├── base.rb                      # Main VSM coordinator (240 lines)
  ├── intelligence.rb              # VSM Intelligence subsystem (364 lines)
  ├── governance.rb                # VSM Governance subsystem (24 lines)
  ├── operations.rb                # VSM Operations subsystem (363 lines)
  └── cli_port.rb                  # External CLI interface (64 lines)
```

**✅ VSM Architecture Compliance:**
- **🧠 Intelligence** (`CityCouncil::Intelligence`) - Environmental scanning, AI analysis, decision making
  - Service request analysis using AI + heuristics
  - Service gap identification 
  - Analysis result caching with confidence scoring
  - Environmental scanning capabilities
- **⚙️ Operations** (`CityCouncil::Operations`) - Department creation, process management, execution
  - Template-based department generation
  - Process launching and monitoring
  - YAML configuration generation
  - Department lifecycle management
- **🏛️ Governance** (`CityCouncil::Governance`) - Policy validation and enforcement
  - Service specification validation
  - Naming convention enforcement
  - Duplicate service prevention
- **🎯 Coordination** (`CityCouncil::Base`) - Main viable system coordinator
  - VSM capsule orchestration
  - SmartMessage integration
  - Health monitoring and process cleanup
  - Department discovery and registration
- **🖥️ CLI Port** (`CityCouncil::CLIPort`) - External interface for testing

**✅ Centralized Logging Architecture:**
- **Shared Logger Instance**: All components use `Common::Logger` which provides the same `SmartMessage::Logger.default` instance
- **Single Configuration**: First component to call `setup_logger` configures the global SmartMessage logger
- **Consistent Output**: All CityCouncil components log to the same destination with consistent formatting
- **No Duplication**: Each class includes `Common::Logger` but all receive the same underlying logger instance

**✅ VSM Message Flow:**
1. **Intelligence** analyzes service requests → emits `:create_service` messages
2. **Operations** receives `:create_service` → executes department creation and process management  
3. **Governance** validates policies throughout the process
4. **Base** coordinates all subsystems and handles external SmartMessage integration

**✅ Template-Based Generation:**
- **Generic Template**: `generic_template.rb` with full VSM architecture
- **YAML Configuration**: Dynamic configuration generation per department
- **Process Management**: Automatic spawning and monitoring of department processes
- **Announcement System**: Real-time status updates via `DepartmentAnnouncementMessage`

**✅ Key Features:**
- ✅ Full VSM compliance with proper subsystem separation
- ✅ AI-powered service analysis using RubyLLM (Intelligence)
- ✅ Template-based department creation (Operations)
- ✅ Dynamic department discovery and registration (Base)
- ✅ CLI interface for testing (`ruby city_council.rb --cli`)
- ✅ **Automatic Department Launching**: Spawns departments as separate processes (Operations)
- ✅ **Department Announcements**: Publishes creation/launch status to all services (Operations)
- ✅ **Process Management**: Tracks department PIDs and cleanup on shutdown (Base)
- ✅ **Centralized Logging**: Single shared logger instance across all components
- ✅ **Modular Design**: Easy to modify individual VSM subsystems independently

#### 2. **Emergency Dispatch Integration** (`emergency_dispatch_center.rb`)
**Why These Changes Were Made:**
The emergency dispatch center needed to handle ANY type of emergency generically, without hard-coding specific department types. Using AI enables dynamic department determination for any scenario.

**Major Architectural Change - AI-Powered Department Routing:**
- **Removed Hard-Coded Logic**: Eliminated all specific department rules (fire, police, water, etc.)
- **AI Integration**: Added RubyLLM to analyze 911 calls and determine appropriate departments
- **Generic Department Mapping**: Can identify any city department type based on emergency description
- **Fallback Logic**: Maintains rule-based backup when AI is unavailable

**Key Updates:**
- **RubyLLM Integration**: `setup_ai()` configures AI model for department analysis
- **AI Department Analysis**: `ai_determine_departments()` uses detailed prompts to analyze emergencies
- **Comprehensive Fallback**: `fallback_determine_departments()` covers major emergency categories
- **Dynamic Department Discovery**: Scans for `*_department.rb` files and adapts to new departments
- **City Council Integration**: Forwards any unhandled emergency types for new department creation
- **Real-time Updates**: Subscribes to department announcements for immediate routing updates

**How AI Analysis Works:**
```ruby
# AI receives comprehensive emergency analysis prompt:
- Emergency type, description, location, severity
- Injury status, hazmat, weapons, vehicles, suspects
- Currently available departments
- Common city department reference list
- Returns JSON array of department names

# Example AI responses:
["animal_control_department"] # for aggressive dog
["transportation_department", "police_department"] # for traffic light malfunction  
["environmental_services_department"] # for illegal dumping
["building_inspection_department"] # for crumbling facade
```

**Fallback Logic Categories:**
- Fire/Rescue → fire_department
- Crime/Accidents → police_department  
- Medical → fire_department (EMS)
- Infrastructure → water_management, utilities, transportation, public_works
- Animals → animal_control_department
- Buildings → building_inspection_department
- Parks → parks_recreation_department

#### 3. **Enhanced Citizen Emergency Scenarios** (`citizen.rb`)
**Why Expanded:**
To thoroughly test the AI-powered generic department routing system with diverse emergency types that require different specialized departments.

**New Emergency Categories Added:**
- **Infrastructure**: Water main breaks, gas leaks, storm drain issues
- **Animal Control**: Aggressive stray dogs, dead wildlife, bee swarms
- **Transportation**: Pothole damage, traffic light malfunctions
- **Environmental**: Illegal dumping, building facade issues
- **Parks & Recreation**: Broken playground equipment, fallen tree branches

**Testing Coverage:**
These diverse scenarios test the AI's ability to determine appropriate departments:
- `animal_control_department` for wildlife issues
- `transportation_department` for road/traffic problems
- `environmental_services_department` for pollution/dumping
- `building_inspection_department` for structural issues
- `parks_recreation_department` for park maintenance
- `utilities_department` for gas leaks
- `public_works_department` for general infrastructure

#### 4. **Service Request Message** (`messages/service_request_message.rb`)
**Purpose:**
Enables communication between Emergency Dispatch and City Council for requesting new departments.

**Message Structure:**
```ruby
ServiceRequestMessage:
  - request_id: Unique identifier
  - requesting_service: Who needs the department (e.g., "emergency-dispatch-center")
  - emergency_type: Type of emergency requiring service
  - description: Details about why the department is needed
  - urgency: Priority level (critical/high/normal/low)
  - original_call_id: Reference to triggering 911 call
  - details: Additional context and original call data
```

#### 5. **Department Announcement System** (`messages/department_announcement_message.rb`)
**Purpose:**
Enables real-time communication about department lifecycle events across all city services.

**Message Structure:**
```ruby
DepartmentAnnouncementMessage:
  - announcement_id: Unique identifier
  - department_name: Full department name (e.g., "animal_control_department")
  - department_file: Ruby filename
  - status: 'created' | 'launched' | 'active' | 'failed'
  - description: Department purpose or error details
  - capabilities: Array of department responsibilities  
  - message_types: Array of message types it handles
  - process_id: PID of launched department process
  - launch_time: When department was launched
  - reason: Why department was created
```

**Status Lifecycle:**
1. **created** - Department file generated, not yet launched
2. **launched** - Process started successfully, PID assigned
3. **active** - Department fully operational (optional confirmation)
4. **failed** - Creation or launch failed with error details

### Enhanced Message Flow: Complete Department Lifecycle

```
1. Citizen reports "Aggressive stray dog attacking people in the park" to 911
   ↓
2. Emergency Dispatch receives call
   - AI analyzes: emergency_type="other", description="aggressive stray dog..."
   - AI determines needed departments: ["animal_control_department"]
   - Checks available departments - animal_control_department doesn't exist
   ↓
3. Dispatch sends ServiceRequestMessage to City Council
   - Department needed: "animal_control_department"
   - Reason: "911 emergency requiring animal control department"
   - Includes full emergency details and AI determination flag
   ↓
4. City Council Intelligence analyzes request
   - Uses AI to understand "animal control" need
   - Generates animal_control_department.rb code
   - Creates animal-related message types
   ↓
5. City Council publishes DepartmentAnnouncementMessage (status: 'created')
   ↓
6. Department file written to disk and made executable
   ↓
7. City Council spawns new department process
   - Checks process started successfully
   - Records PID in @department_processes
   ↓
8. City Council publishes DepartmentAnnouncementMessage (status: 'launched', process_id: PID)
   ↓
9. Emergency Dispatch receives announcement
   - Immediately adds animal_control_department to @available_departments
   - Ready to route future calls without waiting for file system scan
   ↓
10. New animal_control_department process is running and ready for messages
   ↓
11. Future animal emergencies automatically routed to animal_control_department
```

### AI Department Determination Examples

**Example 1 - Gas Leak:**
```
Input: "Gas leak smell near elementary school!"
AI Analysis: Critical infrastructure emergency with hazmat
AI Output: ["utilities_department", "fire_department"]
```

**Example 2 - Traffic Light Malfunction:**  
```
Input: "Traffic lights malfunctioning at major intersection"
AI Analysis: Transportation emergency affecting traffic flow
AI Output: ["transportation_department", "police_department"]
```

**Example 3 - Building Safety:**
```
Input: "Building facade crumbling, bricks falling on sidewalk"  
AI Analysis: Structural safety issue requiring inspection
AI Output: ["building_inspection_department"]
```

### Testing the System

```bash
# Terminal 1: Start City Council
ruby city_council.rb

# Terminal 2: Start Emergency Dispatch
ruby emergency_dispatch_center.rb

# Terminal 3: Run citizen with water emergencies
ruby citizen.rb auto

# Watch as:
# 1. Citizen calls about water line break
# 2. Dispatch forwards to City Council
# 3. City Council generates water_management_department.rb
# 4. New department becomes available for future calls
```

## Architecture Benefits

### Self-Improving System
- City automatically creates services based on actual citizen needs
- No manual intervention required for common department types
- System learns and adapts to community requirements
- **Instant Availability**: New departments are immediately operational and routable

### Fail-Safe Design
- Emergency calls still handled by available departments if possible
- Police department acts as default fallback
- City Council requests logged for manual review if AI fails
- **Process Management**: Automatic cleanup of department processes on shutdown

### Real-Time Communication
- **Instant Updates**: Emergency dispatch immediately knows when departments are available
- **Status Tracking**: Full visibility into department creation and launch status
- **No Polling Required**: Event-driven updates eliminate delay between creation and routing

### Scalability
- New departments follow consistent patterns
- All departments discoverable via file system AND real-time announcements
- Message routing automatically updated
- **Process Isolation**: Each department runs in its own process for stability

## Future Ideas
- Add department dependency management (e.g., utilities depends on public works)
- Implement department lifecycle (decommission unused departments)
- Create inter-department coordination for complex emergencies
- Add citizen feedback loop for department performance

## Questions Explored
- ✅ **How to handle service dependencies?** - Currently handled through message subscriptions
- ✅ **SmartMessage vs VSM pattern?** - Using hybrid approach: SmartMessage for existing, VSM for orchestration
- ✅ **Code security?** - AI generates from safe templates, governance validates
- ✅ **AI autonomy level?** - AI suggests and generates, but code is persisted for review