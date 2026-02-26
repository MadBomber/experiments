#!/usr/bin/env ruby
# decompile.rb - Proof of concept: reconstruct Ruby source from bytecode
#
# YARV bytecode is a stack machine. We simulate the stack,
# translating instructions back into Ruby expressions.

class Decompiler
  def initialize(proc_obj)
    @iseq  = RubyVM::InstructionSequence.of(proc_obj)
    @arr   = @iseq.to_a
    @locals = @arr[10]          # [:a, :b, ...]
    @params = @arr[11]          # {lead_num: 2, ...}
    @body   = @arr[13]          # [1, :EVENT, [:instruction, ...], ...]
    @children = []
    @iseq.each_child { |c| @children << c }
    @child_index = 0
    @lambda = proc_obj.lambda?
  end

  def decompile
    expr = decompile_body(@body)
    params = build_params
    if @lambda
      "->(#{params}) { #{expr} }"
    else
      "proc { |#{params}| #{expr} }"
    end
  end

  private

  def build_params
    count = @params[:lead_num] || 0
    @locals.first(count).join(", ")
  end

  def decompile_body(body)
    stack = []
    statements = []
    instructions = body.select { |i| i.is_a?(Array) }

    instructions.each do |inst|
      op = inst[0]
      case op
      when :getlocal_WC_0
        idx = inst[1]
        # local table is indexed from the end; slot index to name
        name = slot_to_name(idx)
        stack.push(name.to_s)

      when :setlocal_WC_0
        idx = inst[1]
        name = slot_to_name(idx)
        val = stack.pop
        statements << "#{name} = #{val}"

      when :putobject
        stack.push(inst[1].inspect)

      when :putobject_INT2FIX_0_
        stack.push("0")

      when :putobject_INT2FIX_1_
        stack.push("1")

      when :putself
        stack.push("self")

      when :putnil
        stack.push("nil")

      when :putchilledstring, :putstring
        stack.push(inst[1].inspect)

      when :opt_plus, :opt_minus, :opt_mult, :opt_div, :opt_mod,
           :opt_eq, :opt_neq, :opt_lt, :opt_le, :opt_gt, :opt_ge,
           :opt_ltlt
        op_sym = inst[1][:mid]
        b = stack.pop
        a = stack.pop
        stack.push("#{a} #{op_sym} #{b}")

      when :opt_send_without_block
        calldata = inst[1]
        method   = calldata[:mid]
        argc     = calldata[:orig_argc]
        args = stack.pop(argc)
        receiver = stack.pop
        if argc > 0
          stack.push("#{receiver}.#{method}(#{args.join(', ')})")
        else
          stack.push("#{receiver}.#{method}")
        end

      when :send
        calldata = inst[1]
        method   = calldata[:mid]
        argc     = calldata[:orig_argc]
        args     = stack.pop(argc)
        receiver = stack.pop

        # Decompile the child block
        child_iseq = @children[@child_index]
        @child_index += 1
        child_src = decompile_child(child_iseq)

        if argc > 0
          stack.push("#{receiver}.#{method}(#{args.join(', ')}) { #{child_src} }")
        else
          stack.push("#{receiver}.#{method} { #{child_src} }")
        end

      when :newarray
        count = inst[1]
        items = stack.pop(count)
        stack.push("[#{items.join(', ')}]")

      when :newhash
        count = inst[1]
        pairs = stack.pop(count)
        entries = pairs.each_slice(2).map { |k, v| "#{k} => #{v}" }
        stack.push("{ #{entries.join(', ')} }")

      when :branchunless
        # ternary: condition is on stack, followed by true/false branches
        # simplified handling for basic ternary
        condition = stack.pop
        # look ahead for the two value paths
        remaining = instructions[instructions.index(inst)+1..]
        true_val = extract_value(remaining, 0)
        false_val = extract_value(remaining, 1)
        if true_val && false_val
          stack.push("#{condition} ? #{true_val} : #{false_val}")
          break  # done with this body
        end

      when :leave
        # ignore

      when :pop
        val = stack.pop
        statements << val if val

      else
        stack.push("/* #{op} */")
      end
    end

    all = statements + [stack.last].compact
    all.join("; ")
  end

  def decompile_child(child_iseq)
    child_arr = child_iseq.to_a
    child_locals = child_arr[10]
    child_params = child_arr[11]
    child_body   = child_arr[13]
    count = child_params[:lead_num] || 0
    param_names = child_locals.first(count).join(", ")

    # Save and swap state to decompile child body
    saved = [@locals, @params, @body]
    @locals, @params, @body = child_locals, child_params, child_body
    expr = decompile_body(child_body)
    @locals, @params, @body = saved

    if count > 0
      "|#{param_names}| #{expr}"
    else
      expr
    end
  end

  def extract_value(instructions, index)
    values = instructions.select { |i|
      i.is_a?(Array) && (i[0] == :putchilledstring || i[0] == :putstring || i[0] == :putobject)
    }
    val = values[index]
    val[1].inspect if val
  end

  def slot_to_name(slot_idx)
    # YARV slot indices: slot = locals.size + 2 - index
    # So: index = locals.size + 2 - slot
    name_idx = @locals.size + 2 - slot_idx
    @locals[name_idx] || "?local_#{slot_idx}"
  end
end


# ── Test it ──────────────────────────────────────────────────────

examples = [
  ["->(a, b) { a + b }",                          "simple addition"],
  ["->(x) { x > 0 ? \"pos\" : \"neg\" }",         "ternary"],
  ["->(x) { y = x * 2; y + 1 }",                  "local variable"],
  ["->(s) { s.upcase.reverse }",                   "method chain"],
  ["->(items) { items.select { |x| x > 0 }.map { |x| x * 2 } }", "blocks"],
]

examples.each do |src, label|
  pr = eval(src)
  decompiled = Decompiler.new(pr).decompile

  puts "=== #{label} ==="
  puts "  original:    #{src}"
  puts "  decompiled:  #{decompiled}"

  # Verify the decompiled version actually works
  decompiled_pr = eval(decompiled)
  case label
  when "simple addition"
    orig_result = pr.(3, 4)
    new_result  = decompiled_pr.(3, 4)
  when "ternary"
    orig_result = pr.(5)
    new_result  = decompiled_pr.(5)
  when "local variable"
    orig_result = pr.(10)
    new_result  = decompiled_pr.(10)
  when "method chain"
    orig_result = pr.("hello")
    new_result  = decompiled_pr.("hello")
  when "blocks"
    orig_result = pr.([-3, 1, 4, -1, 5])
    new_result  = decompiled_pr.([-3, 1, 4, -1, 5])
  end

  match = orig_result == new_result
  puts "  verify:      #{orig_result.inspect} == #{new_result.inspect} => #{match ? 'PASS' : 'FAIL'}"
  puts
end
