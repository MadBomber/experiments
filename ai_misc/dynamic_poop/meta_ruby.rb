#!/usr/bin/env ruby
# meta_ruby.rb
# Discussion: Ruby Meta-Programming — Replacing Instance Methods at Runtime
#
# Ruby is one of the most powerful languages for meta-programming.
# Everything in Ruby is an object — including classes and modules —
# and the language exposes its own internals in ways most languages don't.

############################################################
# Ruby Meta-Programming Facilities Overview
############################################################

# --- Open Classes ---
# Any class can be reopened and modified at any time, including
# core classes like String, Integer, and Array.

class String
  def shout
    upcase + "!!!"
  end
end

# --- method_missing and respond_to_missing? ---
# Objects can intercept calls to undefined methods and handle them dynamically.

class Ghost
  def method_missing(name, *args)
    "You called #{name} with #{args}"
  end

  def respond_to_missing?(name, include_private = false)
    true
  end
end

# --- define_method ---
# Methods can be created programmatically at runtime.
#
# Example:
#   %w[red green blue].each do |color|
#     define_method("#{color}?") { self.color == color }
#   end

# --- class_eval / module_eval and instance_eval ---
# Execute arbitrary code in the context of a class or instance.
#
#   String.class_eval do
#     def palindrome?
#       self == reverse
#     end
#   end

# --- send and public_send ---
# Invoke methods by name as a string or symbol, bypassing normal dispatch.
#
#   obj.send(:private_method)
#   obj.public_send(:some_method)

# --- Hooks and Callbacks ---
# Ruby provides lifecycle hooks that fire when meta-level events happen:
#   inherited(subclass)          — a class is subclassed
#   included(base) / extended(base) — a module is mixed in
#   method_added / method_removed / method_undefined
#   const_missing                — an undefined constant is referenced

# --- TracePoint ---
# Observe internal VM events — method calls, class definitions, line execution, raises.
#
#   TracePoint.new(:call) do |tp|
#     puts "#{tp.defined_class}##{tp.method_id} called"
#   end.enable

# --- ObjectSpace ---
# Walk every live object in the VM.
#
#   ObjectSpace.each_object(String).count

# --- The Binding Object ---
# Captures the execution context (local variables, self, block) as a first-class object.
# This is what makes ERB templates and Pry work.
#
#   def get_binding
#     x = 42
#     binding
#   end
#   eval("x + 1", get_binding) # => 43

# --- Refinements ---
# A scoped alternative to monkey patching, introduced in Ruby 2.0.
#
#   module StringExt
#     refine String do
#       def shout
#         upcase + "!!!"
#       end
#     end
#   end
#
#   using StringExt
#   "hello".shout # => "HELLO!!!"


############################################################
# Core Question:
# Can an instance method or class method, while executing
# inside a Foo instance, replace the bar method with a
# completely different implementation?
#
# Answer: Yes. Several ways.
############################################################

# --- Approach 1: Replace bar on just THIS instance ---
# Uses define_singleton_method to modify only the object's
# eigenclass (singleton class). No other instance is affected.

class Foo
  def bar
    "original"
  end

  def replace_bar
    define_singleton_method(:bar) do
      "replaced"
    end
  end
end

foo = Foo.new
puts foo.bar          # => "original"
foo.replace_bar
puts foo.bar          # => "replaced"
puts Foo.new.bar      # => "original" (other instances unaffected)


# --- Approach 2: Replace bar on ALL instances from an instance method ---
# Uses self.class.define_method to rewrite the method on the
# class itself, so every instance picks it up.

class Foo2
  def bar
    "original"
  end

  def replace_bar_for_everyone
    self.class.define_method(:bar) do
      "replaced for all"
    end
  end
end

foo2 = Foo2.new
foo2.replace_bar_for_everyone
puts Foo2.new.bar     # => "replaced for all"


# --- Approach 3: Replace bar from a class method ---
# define_method called at the class level rewrites the method
# for all instances.

class Foo3
  def bar
    "original"
  end

  def self.replace_bar
    define_method(:bar) do
      "class-level replacement"
    end
  end
end

puts Foo3.new.bar     # => "original"
Foo3.replace_bar
puts Foo3.new.bar     # => "class-level replacement"


############################################################
# Summary
#
# | Approach                     | Scope           | Mechanism                          |
# |------------------------------|-----------------|------------------------------------|
# | define_singleton_method       | Single instance | Writes to the object's eigenclass  |
# | self.class.define_method      | All instances   | Rewrites the method on the class   |
# | Class.define_method           | All instances   | Same, just called from class context|
#
# The singleton method approach is particularly powerful — it means
# two instances of the same class can have completely different
# implementations of the same method name at the same time.
############################################################


############################################################
# Approach 4: chaos_to_the_rescue — LLM-Powered Method Generation
#
# The chaos_to_the_rescue gem takes method_missing to its logical
# extreme: when an undefined method is called, it intercepts the
# call and uses an LLM (Large Language Model) to generate a real
# implementation on the fly, then defines it on the class so
# subsequent calls execute native Ruby — no LLM roundtrip needed.
#
# Gem: https://github.com/codenamev/chaos_to_the_rescue
#
# This is meta-programming where the MACHINE writes the code
# at runtime rather than the programmer.
############################################################

begin
  require "chaos_to_the_rescue"

  # Configuration — requires an LLM backend (e.g., Ollama running locally)
  ChaosToTheRescue.configure do |config|
    config.enabled            = true
    config.auto_define_methods = true
    config.model              = "qwen3-coder:30b"  # or any Ollama model
    config.allow_everything!
    config.log_level          = :warn
  end

  # --- Basic usage: call a method that doesn't exist ---
  # chaos_to_the_rescue generates it via LLM and defines it on the class.

  class Calculator
    include ChaosToTheRescue::Rescuable

    def initialize(value)
      @value = value
    end
  end

  calc = Calculator.new(42)

  # This method does not exist. chaos_to_the_rescue will:
  #   1. Intercept via method_missing
  #   2. Send the class context + method name to the LLM
  #   3. Receive generated Ruby code back
  #   4. define_method on Calculator with the generated implementation
  #   5. Return the result of calling the newly defined method
  #
  # After the first call, the method exists as a real Ruby method
  # on the class — no LLM overhead on subsequent calls.
  #
  # result = calc.fibonacci_sequence(10)
  # puts result.inspect


  # --- Detecting and persisting generated methods ---
  # You can wrap method_missing to detect when chaos_to_the_rescue
  # has added a new method, then save the generated source to disk
  # so it survives restarts.

  class SmartRobot
    include ChaosToTheRescue::Rescuable

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def greet
      "I am #{name}"
    end

    # Intercept method_missing to detect newly generated methods
    def method_missing(method_name, *args, **kwargs, &block)
      had_method = respond_to?(method_name, true)

      # Delegate to chaos_to_the_rescue via super
      result = super

      # If the method now exists but didn't before, chaos generated it
      unless had_method
        if respond_to?(method_name, true)
          puts "[chaos] Generated method: #{method_name}"
          # In a real system you would persist the source here,
          # e.g., append it to the class's .rb file on disk.
        end
      end

      result
    end
  end

  # robot = SmartRobot.new("Atlas")
  # robot.calculate_escape_vector(10, 20, 50)
  #   => chaos_to_the_rescue generates the method via LLM
  #   => [chaos] Generated method: calculate_escape_vector
  #   => subsequent calls use the cached Ruby method directly

rescue LoadError, NameError => e
  puts "Skipping chaos_to_the_rescue section: #{e.message}"
end


############################################################
# How chaos_to_the_rescue fits the meta-programming spectrum
#
# | Approach                  | Who writes the code? | When?       |
# |---------------------------|----------------------|-------------|
# | define_method             | Programmer           | Runtime     |
# | define_singleton_method   | Programmer           | Runtime     |
# | method_missing            | Programmer           | Every call  |
# | eval / class_eval         | Programmer           | Runtime     |
# | chaos_to_the_rescue       | LLM                  | First call  |
#
# All of the above are enabled by Ruby's meta-programming
# facilities. chaos_to_the_rescue simply replaces the human
# as the author of the generated code, using the same
# define_method / method_missing hooks under the hood.
############################################################


############################################################
# Approach 5: LlmSelfModify — Mixin for LLM-Driven Self-Modification
#
# A reusable module that any class can include to gain the
# ability to generate and install new methods at runtime
# via an LLM. Unlike chaos_to_the_rescue (which intercepts
# method_missing), LlmSelfModify provides an explicit API:
#
#   obj.llm_generate("description of desired method", scope: :instance)
#
# Three scopes are supported:
#   :instance  — adds the method to the class (all instances)
#   :singleton — adds the method to this object only
#   :class     — adds a class-level method (use def self.name in prompt)
#
# Two-pass prompt flow:
#   1. Shape — rewrites casual user input into a precise Ruby
#      method specification (parameter names, types, algorithm
#      steps, concrete Ruby operations for vague terms)
#   2. Generate — sends the shaped spec to the code generator
#
# Built-in safety: validates def...end structure, rejects
# dangerous patterns (system, exec, File, IO, etc.).
#
# Uses the project's existing LlmConfig.ask for Ollama integration.
############################################################

require_relative "lib/llm_self_modify"

# --- Demo class using the mixin ---

class SelfModifyingRobot
  include LlmSelfModify

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def greet
    "I am #{name}"
  end
end

# --- Run the demo (requires Ollama running locally) ---

if __FILE__ == $0
  require "debug_me"
  include DebugMe

  require_relative "lib/logging"
  require_relative "lib/llm_config"

  # Re-open to add the persistence callback now that LOGGER is available
  class SelfModifyingRobot
    def on_method_generated(method_name, scope, code)
      LOGGER.info("[SelfModifyingRobot] Generated #{scope} method :#{method_name}")
      debug_me { [:method_name, :scope, :code] }
    end
  end

  puts "=" * 60
  puts "LlmSelfModify Demo"
  puts "=" * 60

  # Setup LLM
  LlmConfig.setup!

  unless LlmConfig.available?
    puts "Ollama not available — skipping live LLM demo."
    puts "Start Ollama and re-run to see LLM-generated methods."
    exit
  end

  robot = SelfModifyingRobot.new("Atlas")
  puts robot.greet

  puts "\n--- Generating instance method via LLM ---"
  result = robot.llm_generate(
    "add a method called battle_cry that prints the robot's name in big letters shouting a war cry",
    scope: :instance
  )
  debug_me { :result }

  if result[:success]
    puts "Shaped prompt:\n#{result[:shaped_prompt]}"
    puts "\nGenerated: #{result[:method_name]}"
    puts "Code:\n#{result[:code]}"
    puts "Result: #{robot.battle_cry}"
  else
    puts "Failed: #{result[:error]}"
  end

  puts "\n--- Generating singleton method via LLM ---"
  result = robot.llm_generate(
    "give me a method called uid that returns this object's id as hex",
    scope: :singleton
  )
  debug_me { :result }

  if result[:success]
    puts "Shaped prompt:\n#{result[:shaped_prompt]}"
    puts "\nGenerated: #{result[:method_name]}"
    puts "Result: #{robot.uid}"
    puts "Other instance has it? #{SelfModifyingRobot.new('Other').respond_to?(:uid)}"
  else
    puts "Failed: #{result[:error]}"
  end

  puts "\n--- Generating class method via LLM ---"
  result = robot.llm_generate(
    "make a class method called fleet_name that just returns 'Terrarium Fleet'",
    scope: :class
  )
  debug_me { :result }

  if result[:success]
    puts "Shaped prompt:\n#{result[:shaped_prompt]}"
    puts "\nGenerated: #{result[:method_name]}"
    puts "Result: #{SelfModifyingRobot.fleet_name}"
  else
    puts "Failed: #{result[:error]}"
  end
end
