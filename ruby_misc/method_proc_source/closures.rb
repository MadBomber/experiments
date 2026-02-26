#!/usr/bin/env ruby
# closures.rb - Extracting source code from Ruby closures
#
# Two approaches:
#   1. method_source gem  — reads the source file via source_location
#      Only works when a source file exists on disk.
#   2. For dynamically created procs (eval, no file) you must
#      retain the source string yourself. Ruby stores only
#      compiled bytecode in a Proc, not the original source text.

require 'method_source'

# ── Approach 1: File-based (method_source) ──────────────────────

add = ->(a, b) { a + b }

puts "=== method_source gem (reads source file) ==="
puts add.source
puts

# ── Approach 2: Dynamic procs (retain the source) ──────────────

# A simple wrapper that evals a source string and keeps it
def make_proc(source)
  proc_obj = eval(source)
  proc_obj.define_singleton_method(:source) { source }
  proc_obj
end

dynamic_add = make_proc('->(a, b) { a + b }')

puts "=== Dynamic proc (source retained at creation) ==="
puts dynamic_add.source
puts "Result: #{dynamic_add.(3, 4)}"
puts

# ── What Ruby gives you without the source text ─────────────────

puts "=== Introspection available on any proc ==="
puts "  parameters:      #{dynamic_add.parameters.inspect}"
puts "  arity:           #{dynamic_add.arity}"
puts "  lambda?:         #{dynamic_add.lambda?}"
puts "  source_location: #{dynamic_add.source_location.inspect}"
puts

puts "=== Bytecode disassembly (always available) ==="
puts RubyVM::InstructionSequence.of(dynamic_add).disasm
