# Room for Improvement - Common Patterns Analysis

## Overview
Analysis of Ruby service implementations in the multi_program_demo identified several common patterns that could be extracted into reusable mixin modules to reduce code duplication and improve maintainability.

## Common Patterns Identified

### 1. Signal Handlers (100% Duplication)
All services have identical signal handler setup code:
```ruby
def setup_signal_handlers
  %w[INT TERM].each do |signal|
    Signal.trap(signal) do
      puts "\n[emoji] Service shutting down..."
      logger.info("Service shutting down")
      exit(0)
    end
  end
end
```
**Files affected:** All 6 service files

### 2. Message Header Configuration
Services follow similar patterns for setting message headers:
- Setting `from` attribute on message classes
- Publishing with `_sm_header.from` and `_sm_header.to` assignments
- Consistent header manipulation patterns

**Files affected:** All services that publish messages

### 3. Active Incident Management
Fire Department and Police Department share nearly identical patterns:
- Hash tracking active incidents (`@active_fires`, `@active_incidents`)
- Resolution checking loops with duration-based logic
- Unit assignment and return-to-pool mechanisms
- Publishing `EmergencyResolvedMessage` when resolved

**Shared logic:**
- `check_fire_resolutions` / `check_incident_resolutions`
- `resolve_fire` / `resolve_incident`
- Unit assignment based on severity
- Duration-based resolution (10-15 seconds)

### 4. Resource Unit Management
Both emergency services track and manage available units:
```ruby
# Fire Department
@available_engines = ['Engine-1', 'Engine-2', 'Engine-3', 'Ladder-1', 'Rescue-1']
assigned_engines = @available_engines.take(engines_needed)
@available_engines = @available_engines.drop(engines_needed)

# Police Department
@available_units = ['Unit-101', 'Unit-102', 'Unit-103', 'Unit-104']
assigned_units = @available_units.take(units_needed)
@available_units = @available_units.drop(units_needed)
```

### 5. Dispatch Response Handling
House and LocalBank handle dispatch responses similarly:
- Display colored output based on priority/severity
- Log response details
- Start resolution thread with random delay
- Update internal state when resolved

### 6. Service Status Pattern
All services maintain consistent status tracking:
- `@service_name` instance variable
- `@status` instance variable ('healthy', 'warning', 'critical', 'failed')
- `@start_time` timestamp
- Status determination logic based on service-specific conditions

### 7. Main Service Loop
Most services share similar loop structure:
```ruby
def start_service/start_monitoring/start_operations
  loop do
    # Service-specific activity
    sleep(interval)
  end
rescue => e
  puts "[emoji] Error in service: #{e.message}"
  logger.error("Error in service: #{e.message}")
  retry
end
```

## Recommended New Mixin Modules

### 1. **Common::SignalHandler**
**Priority: HIGH** - 100% code duplication
```ruby
module Common
  module SignalHandler
    def setup_signal_handlers
      %w[INT TERM].each do |signal|
        Signal.trap(signal) do
          shutdown_message
          exit(0)
        end
      end
    end
    
    def shutdown_message
      puts "\n#{service_emoji} #{@service_name} shutting down..."
      logger.info("#{@service_name} shutting down")
    end
  end
end
```

### 2. **Common::IncidentManager**
**Priority: HIGH** - Significant shared logic between Fire/Police
```ruby
module Common
  module IncidentManager
    def initialize_incident_tracking
      @active_incidents = {}
      @available_units = []
    end
    
    def assign_units(units_needed)
      units_needed = [@available_units.size, units_needed].min
      assigned = @available_units.shift(units_needed)
      assigned
    end
    
    def return_units(units)
      @available_units.concat(units)
    end
    
    def check_incident_resolutions(base_duration = 10..15)
      @active_incidents.each do |id, incident|
        duration = (Time.now - incident[:start_time]).to_i
        if duration > rand(base_duration)
          resolve_incident(id, incident, duration)
        end
      end
    end
  end
end
```

### 3. **Common::MessageSetup**
**Priority: MEDIUM** - Reduces boilerplate
```ruby
module Common
  module MessageSetup
    def setup_message_defaults(*message_classes)
      message_classes.each do |klass|
        klass.from = @service_name
      end
    end
    
    def publish_with_headers(message, to: nil)
      message._sm_header.from = @service_name
      message._sm_header.to = to if to
      message.publish
    end
  end
end
```

### 4. **Common::DispatchResponder**
**Priority: MEDIUM** - Shared by House and Bank
```ruby
module Common
  module DispatchResponder
    def handle_dispatch_response(dispatch, dispatch_type)
      display_dispatch(dispatch, dispatch_type)
      log_dispatch(dispatch, dispatch_type)
      start_resolution_thread(dispatch)
    end
    
    private
    
    def display_dispatch(dispatch, type)
      # Colored output logic
    end
    
    def start_resolution_thread(dispatch)
      Thread.new do
        sleep(rand(180..600))
        resolve_dispatch(dispatch)
      end
    end
  end
end
```

### 5. **Common::ServiceLoop**
**Priority: LOW** - Minor benefit
```ruby
module Common
  module ServiceLoop
    def run_service_loop(activity_method, sleep_interval)
      loop do
        send(activity_method)
        sleep(sleep_interval)
      end
    rescue => e
      handle_service_error(e)
      retry
    end
    
    def handle_service_error(error)
      puts "#{service_emoji} Error in #{@service_name}: #{error.message}"
      logger.error("Error in #{@service_name}: #{error.message}")
    end
  end
end
```

## Implementation Priority

1. **Immediate Implementation:**
   - `Common::SignalHandler` - Zero risk, 100% duplication
   - `Common::IncidentManager` - High value for Fire/Police departments

2. **Next Phase:**
   - `Common::MessageSetup` - Simplifies message handling
   - `Common::DispatchResponder` - Consolidates House/Bank response logic

3. **Consider Later:**
   - `Common::ServiceLoop` - Minor improvement, may reduce flexibility

## Benefits of Refactoring

- **Reduced Code Duplication:** ~200-300 lines of duplicated code can be eliminated
- **Consistency:** Ensures all services handle common operations identically
- **Maintainability:** Bug fixes and improvements in one place benefit all services
- **Testability:** Common behaviors can be tested once in isolation
- **Onboarding:** New developers can understand patterns more quickly

## Migration Strategy

1. Start with `Common::SignalHandler` as a proof of concept
2. Test thoroughly with one service before applying to all
3. Implement one mixin at a time to avoid breaking changes
4. Keep service-specific behavior in the service classes
5. Document the mixins clearly for future developers