#!/usr/bin/env ruby
# experiments/using_methods_as_data/rule_based_system.rb

require 'debug_me'
include DebugMe

require 'hashie'
require 'yaml'

require_relative 'rules'


module Reflection
  def self.display_class_methods_and_params(mod)
    class_methods = mod.singleton_methods(false) # Get only methods defined directly in the module

    class_methods.each do |method|
      puts "Method: #{method}"

      # Getting parameters info for each method
      parameters = mod.method(method).parameters
      
      puts "Parameters:"

      if parameters.empty?
        puts "  - None"
      else
        parameters.each_with_index do |(type, name), index|
          # type => :req || :keyreq means required
          # type => :opt || :key means optional
          puts "  - #{index + 1}: #{name} (#{type})"
        end
      end

      puts "-" * 30 # Just a separator for readability
    end
  end

  def self.get_required_class_method_params(mod)
    method_params = {}

    class_methods = mod.singleton_methods(false)
    
    class_methods.each do |method|
      parameters = mod.method(method).parameters.select { |type, _| type == :keyreq }
      method_params[method] = parameters # .map(&:last) # Collecting only the names of required keyword arguments
    end
    
    method_params
  end
end


class Rule
  attr_reader :slots, :logic

  # slots (Array or Arrays) where
  #   an entry is [type, name]
  #   type is either :req or :keyreq meaning the slot is required
  #   type is either :opt or :key meaning it is optional
  def initialize(slots:, logic:)
    @slots = slots
    @logic = logic
  end

  def applies_to?(fact)
    required_names = slots.select { |type, _| [:req, :keyreq].include?(type) }.map(&:last)
    (required_names - fact.keys.map(&:to_sym)).empty?
  end
end

# This really is not a RETE algorithm.
# Its just a notional framework for facts and rules

class RuleBasedSystem
  def initialize
    @rules = []
    @facts = []
  end

  def add_rule(slots:, logic:)
    rule = Rule.new(slots: slots, logic: logic)
    @rules << rule
  end

  def add_fact(fact)
    @facts << Hashie::Mash.new(fact)
  end

  def run
    @rules.each do |rule|
      applicable_facts(rule).each do |fact|
        parameters = prepare_parameters(rule.slots, fact)
        fired = rule.logic.call(*parameters) # Adjusted for dynamic parameters
        puts "Rule applied to #{fact}" if fired
      end
    end
  end


  def load_facts_from_yaml(file_path)
    YAML.load_file(file_path).each do |fact|
      add_fact(fact)
    end
  end

  def load_rules_from_file(file_path)
    basename = File.basename(file_path, '.rb')
    require_relative file_path
    
    module_name = basename.split('_').collect(&:capitalize).join
    mod = Object.const_get(module_name)
    
    rules = Reflection.get_required_class_method_params(mod)
    
    rules.each do |method_name, slots|
      logic = proc { mod.send(method_name, **_1) }
      add_rule(slots: slots, logic: logic)
    end
  end


  private

  def applicable_facts(rule)
    @facts.select { |fact| rule.applies_to?(fact) }
  end


  # Prepare parameters based on rule slots and fact
  def prepare_parameters(slots, fact)
    parameters = []
    keyword_parameters = {}

    slots.each do |type, name|
      value = fact[name]

      case type
      when :req, :opt
        parameters << value
      when :keyreq, :key
        keyword_parameters[name] = value
      end
    end

    # If there are keyword parameters, they must be passed as a hash at the end of positional parameters
    parameters << keyword_parameters unless keyword_parameters.empty?
    
    parameters
  end
end

Reflection.display_class_methods_and_params(Rules)
params = Reflection.get_required_class_method_params(Rules)

debug_me{[
  :params
]}

exit


# Example Usage
rete = RuleBasedSystem.new


# Load facts from a YAML file
# Assuming the YAML file has a list of facts
rete.load_facts_from_yaml('facts.yml')

# Load rules from a custom file
# Example rule file line: "age | lambda { |fact| puts \"#{fact.name} is over 18\" if fact.age > 18 }"
rete.load_rules_from_file('rules.txt')


# Adding a rule to check if a fact has an 'age' slot and its value is greater than 18
rete.add_rule(
  slots: [:age],
  logic: lambda { |fact| puts "#{fact.name} is over 18" if fact.age > 18 }
)

# Add facts
rete.add_fact(name: 'John Doe', age: 25)
rete.add_fact(name: 'Jane Doe', age: 17)

# Run the inference engine
rete.run


__END__

```yaml
- name: Alice
  age: 30
- name: Bob
  age: 15
- name: Charlie
  age: 22
```

