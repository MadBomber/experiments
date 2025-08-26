#!/usr/bin/env ruby

require 'time'
require 'json'

class EmergencyLogAnalyzer
  attr_reader :calls, :dispatches, :resolutions, :departments_used, :missing_departments

  def initialize(log_dir = 'log')
    @log_dir = log_dir
    @calls = []
    @dispatches = []
    @resolutions = []
    @departments_used = Hash.new(0)
    @missing_departments = []
    @call_types = Hash.new(0)
    @police_incidents = []
    @fire_incidents = []
  end

  def analyze
    puts "\n" + "="*80
    puts "📊 Emergency Dispatch System Log Analysis"
    puts "="*80
    
    parse_emergency_dispatch_log
    parse_police_log
    parse_fire_log
    
    generate_report
  end

  private

  def parse_emergency_dispatch_log
    log_file = File.join(@log_dir, 'emergency_dispatch_center.log')
    return unless File.exist?(log_file)
    
    print "\n📖 Parsing emergency dispatch center log..."
    
    File.foreach(log_file) do |line|
      # Parse 911 calls
      if line =~ /WARN.*911 CALL (911-\d+-\d+-\d+): (\w+) at (.+?) - (.+)$/
        call_id = $1
        call_type = $2
        location = $3
        description = $4
        
        if line =~ /\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/
          timestamp = Time.parse($1)
        end
        
        @calls << {
          id: call_id,
          type: call_type,
          location: location,
          description: description,
          timestamp: timestamp
        }
        
        @call_types[call_type] += 1
      end
      
      # Parse AI department determinations
      if line =~ /AI determined departments: (.+)$/
        departments = $1.split(', ')
        departments.each { |dept| @departments_used[dept] += 1 }
      end
      
      # Parse missing departments
      if line =~ /Missing departments for call: (.+)$/
        missing = $1.split(', ')
        @missing_departments.concat(missing)
      end
      
      # Parse department creation requests
      if line =~ /Requested new department from City Council: (.+)$/
        dept = $1
        @missing_departments << dept unless @missing_departments.include?(dept)
      end
      
      # Parse forwarded calls
      if line =~ /Forwarded call (911-\d+-\d+-\d+) to (\w+ Department)/
        call_id = $1
        department = $2
        
        @dispatches << {
          call_id: call_id,
          department: department,
          type: 'forwarded'
        }
      end
      
      # Parse call resolutions
      if line =~ /Call (911-\d+-\d+-\d+) handled after (\d+) seconds/
        call_id = $1
        duration = $2.to_i
        
        @resolutions << {
          call_id: call_id,
          duration_seconds: duration
        }
      end
    end
    
    puts " ✓ Found #{@calls.size} emergency calls"
  end

  def parse_police_log
    log_file = File.join(@log_dir, 'police_department.log')
    return unless File.exist?(log_file)
    
    print "📖 Parsing police department log..."
    
    File.foreach(log_file) do |line|
      # Parse police dispatches
      if line =~ /Dispatched (.+?) to (\w+) (\w+-\d+)$/
        units = $1.split(', ')
        incident_type = $2
        incident_id = $3
        
        @police_incidents << {
          units: units,
          type: incident_type,
          id: incident_id,
          resolved: false
        }
      end
      
      # Parse incident resolutions
      if line =~ /Incident (\w+-\d+) resolved.* after ([\d.]+) minutes$/
        incident_id = $1
        duration = $2.to_f
        
        incident = @police_incidents.find { |i| i[:id] == incident_id }
        if incident
          incident[:resolved] = true
          incident[:duration_minutes] = duration
        end
      end
    end
    
    puts " ✓ Found #{@police_incidents.size} police incidents"
  end

  def parse_fire_log
    log_file = File.join(@log_dir, 'fire_department.log')
    return unless File.exist?(log_file)
    
    print "📖 Parsing fire department log..."
    
    File.foreach(log_file) do |line|
      # Parse fire dispatches
      if line =~ /Dispatched (.+?) to (\w+) (\w+-\d+)$/
        units = $1.split(', ')
        incident_type = $2
        incident_id = $3
        
        @fire_incidents << {
          units: units,
          type: incident_type,
          id: incident_id,
          resolved: false
        }
      end
      
      # Parse fire resolutions
      if line =~ /Fire (\w+-\d+) extinguished.* after ([\d.]+) minutes$/
        incident_id = $1
        duration = $2.to_f
        
        incident = @fire_incidents.find { |i| i[:id] == incident_id }
        if incident
          incident[:resolved] = true
          incident[:duration_minutes] = duration
        end
      end
    end
    
    puts " ✓ Found #{@fire_incidents.size} fire incidents"
  end

  def generate_report
    puts "\n" + "="*80
    puts "📊 EMERGENCY DISPATCH STATISTICAL REPORT"
    puts "="*80
    
    # Time period analysis
    if @calls.any?
      start_time = @calls.map { |c| c[:timestamp] }.compact.min
      end_time = @calls.map { |c| c[:timestamp] }.compact.max
      duration_minutes = ((end_time - start_time) / 60).round(1) if start_time && end_time
      
      puts "\n⏰ TIME PERIOD"
      puts "   Start: #{start_time&.strftime('%H:%M:%S')}"
      puts "   End: #{end_time&.strftime('%H:%M:%S')}"
      puts "   Duration: #{duration_minutes} minutes" if duration_minutes
    end
    
    # Call volume statistics
    puts "\n📞 911 CALL VOLUME"
    puts "   Total Calls: #{@calls.size}"
    puts "   Call Rate: #{(@calls.size / (duration_minutes || 1)).round(2)} calls/minute" if duration_minutes
    puts "   Unique Locations: #{@calls.map { |c| c[:location] }.uniq.size}"
    
    # Call types breakdown
    puts "\n📋 CALL TYPES BREAKDOWN"
    @call_types.sort_by { |_, count| -count }.each do |type, count|
      percentage = (count.to_f / @calls.size * 100).round(1)
      type_display = type.gsub('_', ' ').capitalize
      puts "   #{type_display}: #{count} calls (#{percentage}%)"
    end
    
    # Department utilization
    puts "\n🏢 DEPARTMENT UTILIZATION"
    puts "   Total Departments Used: #{@departments_used.keys.size}"
    puts "\n   Top 5 Most Used Departments:"
    @departments_used.sort_by { |_, count| -count }.first(5).each do |dept, count|
      dept_display = dept.split('_').map(&:capitalize).join(' ')
      puts "   • #{dept_display}: #{count} calls"
    end
    
    # Missing departments
    if @missing_departments.any?
      puts "\n⚠️  MISSING DEPARTMENTS (Requested from City Council)"
      @missing_departments.uniq.each do |dept|
        puts "   • #{dept.split('_').map(&:capitalize).join(' ')}"
      end
    end
    
    # Police department statistics
    puts "\n🚔 POLICE DEPARTMENT ACTIVITY"
    puts "   Total Incidents: #{@police_incidents.size}"
    puts "   Resolved: #{@police_incidents.count { |i| i[:resolved] }}"
    
    if @police_incidents.any? { |i| i[:resolved] }
      avg_response = @police_incidents
        .select { |i| i[:resolved] && i[:duration_minutes] }
        .map { |i| i[:duration_minutes] }
        .sum / @police_incidents.count { |i| i[:resolved] }.to_f
      puts "   Average Resolution Time: #{avg_response.round(2)} minutes (simulated)"
    end
    
    police_units = @police_incidents.flat_map { |i| i[:units] }.uniq.sort
    puts "   Units Deployed: #{police_units.join(', ')}" if police_units.any?
    
    # Fire department statistics
    puts "\n🚒 FIRE DEPARTMENT ACTIVITY"
    puts "   Total Incidents: #{@fire_incidents.size}"
    puts "   Resolved: #{@fire_incidents.count { |i| i[:resolved] }}"
    
    if @fire_incidents.any? { |i| i[:resolved] }
      avg_response = @fire_incidents
        .select { |i| i[:resolved] && i[:duration_minutes] }
        .map { |i| i[:duration_minutes] }
        .sum / @fire_incidents.count { |i| i[:resolved] }.to_f
      puts "   Average Resolution Time: #{avg_response.round(2)} minutes (simulated)"
    end
    
    fire_units = @fire_incidents.flat_map { |i| i[:units] }.uniq.sort
    puts "   Units Deployed: #{fire_units.join(', ')}" if fire_units.any?
    
    # Call resolution statistics
    puts "\n⏱️  CALL RESOLUTION"
    puts "   Calls with Tracked Resolution: #{@resolutions.size}"
    
    if @resolutions.any?
      avg_duration = @resolutions.map { |r| r[:duration_seconds] }.sum / @resolutions.size.to_f
      min_duration = @resolutions.map { |r| r[:duration_seconds] }.min
      max_duration = @resolutions.map { |r| r[:duration_seconds] }.max
      
      puts "   Average Resolution Time: #{avg_duration.round(0)} seconds"
      puts "   Fastest Resolution: #{min_duration} seconds"
      puts "   Slowest Resolution: #{max_duration} seconds"
    end
    
    # System performance
    puts "\n⚡ SYSTEM PERFORMANCE"
    forwarded_count = @dispatches.count { |d| d[:type] == 'forwarded' }
    puts "   Direct Department Forwards: #{forwarded_count}"
    puts "   Unresolved Calls: #{@calls.size - @resolutions.size}"
    
    if @calls.size > 0
      resolution_rate = (@resolutions.size.to_f / @calls.size * 100).round(1)
      puts "   Resolution Rate: #{resolution_rate}%"
    end
    
    # Summary insights
    puts "\n💡 KEY INSIGHTS"
    puts "   • System handled #{@calls.size} emergency calls successfully"
    puts "   • #{@departments_used.keys.size} different departments were utilized"
    puts "   • Police handled #{@police_incidents.count { |i| i[:resolved] }} incidents"
    puts "   • Fire handled #{@fire_incidents.count { |i| i[:resolved] }} incidents"
    
    if @missing_departments.any?
      puts "   • City Council dynamically created #{@missing_departments.uniq.size} missing department(s)"
    end
    
    puts "\n" + "="*80
    puts "📊 End of Report - Generated at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "="*80
  end
end

# Run the analyzer if executed directly
if __FILE__ == $0
  analyzer = EmergencyLogAnalyzer.new
  analyzer.analyze
  
  # Export option
  if ARGV.include?('--export-json')
    export_data = {
      calls: analyzer.calls,
      dispatches: analyzer.dispatches,
      resolutions: analyzer.resolutions,
      departments_used: analyzer.departments_used,
      missing_departments: analyzer.missing_departments,
      timestamp: Time.now.iso8601
    }
    
    File.write('emergency_analysis.json', JSON.pretty_generate(export_data))
    puts "\n📁 Analysis exported to emergency_analysis.json"
  end
end