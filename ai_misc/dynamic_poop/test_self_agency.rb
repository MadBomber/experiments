# frozen_string_literal: true

require "debug_me"
include DebugMe

require_relative "lib/self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Foo
  include SelfAgency
end

passed = 0
failed = 0

# --------------------------------------------------------------------------
# Test 1: Instance method — add two integers
# --------------------------------------------------------------------------
debug_me "Test 1: Generate an instance method that adds two integers"
begin
  foo = Foo.new
  name = foo._("an instance method to add two integers, return the result")
  result = foo.send(name, 1, 1)

  if result == 2
    debug_me "  PASS — #{name}(1,1) => #{result}"
    passed += 1
  else
    debug_me "  FAIL — expected 2, got #{result.inspect}"
    failed += 1
  end
rescue => e
  debug_me "  FAIL — #{e.class}: #{e.message}"
  failed += 1
end

# --------------------------------------------------------------------------
# Test 2: Singleton method — only on one instance
# --------------------------------------------------------------------------
debug_me "Test 2: Generate a singleton method (only on one instance)"
begin
  foo1 = Foo.new
  foo2 = Foo.new
  name = foo1._("a method called solo_greeting that returns the string 'hello from solo'", scope: :singleton)

  result = foo1.send(name)
  has_method = foo2.respond_to?(name)

  if result == "hello from solo" && !has_method
    debug_me "  PASS — foo1.#{name} => #{result.inspect}, foo2 does not respond"
    passed += 1
  elsif has_method
    debug_me "  FAIL — foo2 should NOT respond to #{name}"
    failed += 1
  else
    debug_me "  FAIL — expected 'hello from solo', got #{result.inspect}"
    failed += 1
  end
rescue => e
  debug_me "  FAIL — #{e.class}: #{e.message}"
  failed += 1
end

# --------------------------------------------------------------------------
# Test 3: Class method
# --------------------------------------------------------------------------
debug_me "Test 3: Generate a class method"
begin
  foo = Foo.new
  name = foo._("a class method called class_ping that returns the string 'pong'", scope: :class)

  result = Foo.send(name)
  if result == "pong"
    debug_me "  PASS — Foo.#{name} => #{result.inspect}"
    passed += 1
  else
    debug_me "  FAIL — expected 'pong', got #{result.inspect}"
    failed += 1
  end
rescue => e
  debug_me "  FAIL — #{e.class}: #{e.message}"
  failed += 1
end

# --------------------------------------------------------------------------
# Test 4: Security rejection
# --------------------------------------------------------------------------
debug_me "Test 4: Verify security rejection (method using system())"
begin
  foo = Foo.new
  foo._("a method called hack that calls system('ls')")
  debug_me "  FAIL — should have raised, but didn't"
  failed += 1
rescue SelfAgency::SecurityError
  debug_me "  PASS — SecurityError raised as expected"
  passed += 1
rescue SelfAgency::ValidationError
  debug_me "  PASS — ValidationError raised (dangerous pattern caught in validation)"
  passed += 1
rescue => e
  debug_me "  FAIL — wrong exception: #{e.class}: #{e.message}"
  failed += 1
end

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
debug_me ""
debug_me "Results: #{passed} passed, #{failed} failed out of #{passed + failed}"
exit(failed > 0 ? 1 : 0)
