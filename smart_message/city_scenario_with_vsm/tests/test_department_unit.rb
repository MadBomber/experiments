#!/usr/bin/env ruby
# test_department_unit.rb - Unit test program for generic_department.rb
#
# This test program validates the functionality of the generic department
# by testing various components and message handling capabilities.

require_relative 'generic_department'
require 'minitest/autorun'
require 'minitest/spec'
require 'timeout'
require 'thread'

class GenericDepartmentTest < Minitest::Test
  def setup
    puts "\n🧪 Setting up test environment..."
    @config_file = 'test_department_unit.yml'
    
    # Ensure config file exists
    unless File.exist?(@config_file)
      skip "Config file #{@config_file} not found. Please run from the correct directory."
    end
    
    # Load config for testing
    @config = YAML.load_file(@config_file)
    puts "✅ Config loaded: #{@config['department']['name']}"
  end
  
  def teardown
    puts "🧹 Cleaning up test environment..."
    # Clean up any test artifacts
  end

  def test_config_loading
    puts "\n🧪 TEST: Config Loading"
    
    assert File.exist?(@config_file), "Config file should exist"
    assert_kind_of Hash, @config, "Config should be a hash"
    assert @config['department'], "Config should have department section"
    assert_equal 'test_department_unit', @config['department']['name']
    
    puts "✅ Config loading test passed"
  end

  def test_vsm_component_classes_exist
    puts "\n🧪 TEST: VSM Component Classes"
    
    assert defined?(GenericDepartmentIdentity), "GenericDepartmentIdentity should be defined"
    assert defined?(GenericDepartmentGovernance), "GenericDepartmentGovernance should be defined" 
    assert defined?(GenericDepartmentIntelligence), "GenericDepartmentIntelligence should be defined"
    assert defined?(GenericDepartmentOperations), "GenericDepartmentOperations should be defined"
    
    puts "✅ VSM component classes test passed"
  end

  def test_vsm_identity_initialization
    puts "\n🧪 TEST: VSM Identity Initialization"
    
    identity = GenericDepartmentIdentity.new(config: @config)
    assert_kind_of GenericDepartmentIdentity, identity
    puts "✅ VSM Identity initialization test passed"
  end

  def test_vsm_governance_initialization  
    puts "\n🧪 TEST: VSM Governance Initialization"
    
    governance = GenericDepartmentGovernance.new(config: @config)
    assert_kind_of GenericDepartmentGovernance, governance
    
    # Test action validation
    assert governance.validate_action("Process test messages"), "Should validate configured capability"
    refute governance.validate_action("Invalid action"), "Should reject invalid action"
    
    puts "✅ VSM Governance initialization test passed"
  end

  def test_vsm_intelligence_initialization
    puts "\n🧪 TEST: VSM Intelligence Initialization"
    
    intelligence = GenericDepartmentIntelligence.new(config: @config)
    assert_kind_of GenericDepartmentIntelligence, intelligence
    puts "✅ VSM Intelligence initialization test passed"
  end

  def test_vsm_operations_initialization
    puts "\n🧪 TEST: VSM Operations Initialization"
    
    operations = GenericDepartmentOperations.new(config: @config)
    assert_kind_of GenericDepartmentOperations, operations
    puts "✅ VSM Operations initialization test passed"
  end

  def test_message_routing_rules
    puts "\n🧪 TEST: Message Routing Rules"
    
    routing_rules = @config['routing_rules']
    assert routing_rules, "Should have routing rules"
    assert routing_rules['emergency_911_message'], "Should have emergency message routing"
    assert routing_rules['health_check_message'], "Should have health check routing"
    
    puts "✅ Message routing rules test passed"
  end

  def test_action_configurations
    puts "\n🧪 TEST: Action Configurations"
    
    action_configs = @config['action_configs']
    assert action_configs, "Should have action configurations"
    assert action_configs['handle_test_emergency'], "Should have test emergency action config"
    assert action_configs['respond_health_check'], "Should have health check action config"
    
    # Test response template
    template = action_configs['handle_test_emergency']['response_template']
    assert_includes template, '{{emergency_type}}', "Template should have emergency_type placeholder"
    assert_includes template, '{{location}}', "Template should have location placeholder"
    
    puts "✅ Action configurations test passed"
  end

  def test_template_substitution
    puts "\n🧪 TEST: Template Substitution"
    
    operations = GenericDepartmentOperations.new(config: @config)
    
    template = "🧪 TEST: {{emergency_type}} at {{location}}"
    data = { 'emergency_type' => 'Fire', 'location' => '123 Test St' }
    
    result = operations.send(:generate_response, template, data)
    expected = "🧪 TEST: Fire at 123 Test St"
    
    assert_equal expected, result, "Template substitution should work correctly"
    puts "✅ Template substitution test passed"
  end

  def test_statistics_tracking
    puts "\n🧪 TEST: Statistics Tracking"
    
    operations = GenericDepartmentOperations.new(config: @config)
    stats = operations.instance_variable_get(:@statistics)
    
    assert_kind_of Hash, stats, "Statistics should be a hash"
    assert_equal 0, stats[:successful_operations], "Should start with 0 successful operations"
    
    puts "✅ Statistics tracking test passed"
  end

  def test_capability_setup
    puts "\n🧪 TEST: Capability Setup"
    
    operations = GenericDepartmentOperations.new(config: @config)
    capabilities = operations.instance_variable_get(:@capabilities)
    
    assert_kind_of Array, capabilities, "Capabilities should be an array"
    assert_includes capabilities, "Process test messages", "Should include configured capabilities"
    
    puts "✅ Capability setup test passed"
  end

  def test_logger_configuration
    puts "\n🧪 TEST: Logger Configuration"
    
    # Test that logger level configuration works
    assert_equal 'debug', @config['logging']['level'], "Should have debug logging level"
    assert_equal 30, @config['logging']['statistics_interval'], "Should have 30 second stats interval"
    
    puts "✅ Logger configuration test passed"
  end
end

# Interactive Test Runner
class GenericDepartmentInteractiveTest
  def initialize
    @config_file = 'test_department_unit.yml'
    @config = YAML.load_file(@config_file)
    puts "🧪 Interactive Test Environment Initialized"
    puts "📋 Department: #{@config['department']['display_name']}"
  end

  def run_department_startup_test
    puts "\n🚀 INTEGRATION TEST: Department Startup"
    puts "⚠️  This will start the actual department - press Ctrl+C to stop"
    
    begin
      # This will run the actual department for a few seconds
      Timeout::timeout(10) do
        load './generic_department.rb'
      end
    rescue Timeout::Error
      puts "✅ Department startup test completed (timed out as expected)"
    rescue => e
      puts "❌ Department startup failed: #{e.message}"
      puts "🔍 Error details: #{e.class.name}"
      return false
    end
    
    true
  end

  def run_vsm_integration_test
    puts "\n🔧 INTEGRATION TEST: VSM Component Integration"
    
    begin
      # Test VSM capsule creation process
      service_name = @config['department']['name']
      
      puts "🏗️  Testing VSM capsule creation..."
      
      # Create components individually first
      identity = GenericDepartmentIdentity.new(config: @config)
      governance = GenericDepartmentGovernance.new(config: @config)
      intelligence = GenericDepartmentIntelligence.new(config: @config)
      operations = GenericDepartmentOperations.new(config: @config)
      
      puts "✅ All VSM components created successfully"
      
      # Test component interactions
      puts "🧠 Testing Intelligence routing..."
      # Create a mock VSM message
      test_message = VSM::Message.new(
        kind: :emergency_911_message,
        payload: { emergency_type: 'test', location: 'test location' }
      )
      
      # Test that intelligence can find routing rules
      rule = intelligence.send(:find_routing_rule, 'emergency_911_message')
      assert rule, "Should find routing rule for emergency messages"
      
      puts "✅ VSM integration test passed"
      
    rescue => e
      puts "❌ VSM integration test failed: #{e.message}"
      puts "🔍 Error: #{e.class.name}"
      puts "📍 Backtrace: #{e.backtrace.first(3).join("\n")}"
      return false
    end
    
    true
  end

  def run_all_tests
    puts "\n🏁 Running All Integration Tests"
    
    results = []
    results << run_vsm_integration_test
    
    if results.all?
      puts "\n✅ All integration tests passed!"
    else
      puts "\n❌ Some integration tests failed"
    end
    
    results.all?
  end
end

# Main execution
if __FILE__ == $0
  puts "🧪 Generic Template Unit Test Suite"
  puts "=" * 50
  
  # Check if we're in test mode or interactive mode
  if ARGV.include?('--interactive') || ARGV.include?('-i')
    puts "🖥️  Running in interactive mode..."
    tester = GenericDepartmentInteractiveTest.new
    tester.run_all_tests
  elsif ARGV.include?('--startup-test') || ARGV.include?('-s')
    puts "🚀 Running startup test..."
    tester = GenericDepartmentInteractiveTest.new  
    tester.run_department_startup_test
  else
    puts "🔬 Running unit tests..."
    # Run minitest unit tests
    # Tests will run automatically
  end
end