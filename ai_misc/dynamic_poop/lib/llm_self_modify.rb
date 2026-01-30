# frozen_string_literal: true

# Mixin module that gives any class the ability to modify itself at
# runtime via LLM-generated Ruby code.
#
# Usage:
#   class MyRobot
#     include LlmSelfModify
#
#     def on_method_generated(method_name, scope, code)
#       # optional persistence callback
#     end
#   end
#
#   robot = MyRobot.new
#   robot.llm_generate("Define a method called flee that returns a random direction", scope: :instance)
#
module LlmSelfModify
  # Runtime sandbox — shadows dangerous Kernel methods so they raise
  # SecurityError instead of executing. Each generated method is defined
  # inside an anonymous module that includes this Sandbox, placing these
  # shadows ahead of Kernel in Ruby's method resolution order.
  #
  # Ancestor chain after include:
  #   MyClass → AnonModule → Sandbox → Object → Kernel → BasicObject
  #
  # When generated code calls system("ls"), Ruby finds Sandbox#system
  # before Kernel#system → SecurityError.
  #
  # Note: Including the sandbox in the class's ancestor chain also
  # affects non-generated methods on that class. This is intentional —
  # a class that opts into LlmSelfModify accepts sandboxed restrictions
  # on dangerous operations. The class author can bypass this by calling
  # Kernel methods directly on a different receiver if needed in their
  # own (non-generated) code.
  module Sandbox
    private

    def system(*)  = raise(SecurityError, "system() blocked by LlmSelfModify sandbox")
    def exec(*)    = raise(SecurityError, "exec() blocked by LlmSelfModify sandbox")
    def spawn(*)   = raise(SecurityError, "spawn() blocked by LlmSelfModify sandbox")
    def fork(*)    = raise(SecurityError, "fork() blocked by LlmSelfModify sandbox")
    def `(*)       = raise(SecurityError, "backtick execution blocked by LlmSelfModify sandbox")
    def open(*)    = raise(SecurityError, "open() blocked by LlmSelfModify sandbox")
  end

  DANGEROUS_PATTERNS = /
    \b(system|exec|spawn|fork|abort|exit)\b |
    `[^`]*`                                 |
    %x\{                                    |
    %x\[                                    |
    %x\(                                    |
    \bFile\.\b                              |
    \bIO\.\b                                |
    \bKernel\.\b                            |
    \bOpen3\.\b                             |
    \bProcess\.\b                           |
    \brequire\b                             |
    \bload\b                                |
    \b__send__\b                            |
    \beval\b                                |
    \bsend\b(?!\s*\()                       |
    \bremove_method\b                       |
    \bundef_method\b
  /x

  # Step 1: Rewrite a casual user prompt into a precise Ruby method spec.
  SHAPE_SYSTEM_PROMPT = <<~PROMPT
    You are a prompt engineer specializing in Ruby code generation.
    Your job is to take a casual, natural-language request and rewrite it
    into a precise, unambiguous technical specification for a Ruby method.

    Rules for the rewritten prompt:
    - State the exact method name (snake_case). If the user didn't name one,
      infer a clear name from the description.
    - State the method signature: parameter names, types, defaults.
    - State the return type and value.
    - Describe the algorithm step by step.
    - Translate vague terms into concrete Ruby operations. Examples:
        "print in random places on the terminal" →
          "Use ANSI escape codes (\\e[row;colH) to move the cursor to
           randomly chosen row/col positions within an 80×24 terminal grid,
           then print the text at each position."
        "returns a random direction" →
          "Return one of the four cardinal direction symbols
           [:north, :south, :east, :west] chosen with Array#sample."
    - If the request mentions visual output, specify the exact mechanism
      (ANSI escapes, $stdout.write, puts, etc.).
    - If the request mentions randomness, specify using Ruby's rand / sample.
    - Preserve every concrete detail the user gave (names, counts, strings).
    - Do NOT generate Ruby code. Output ONLY the rewritten specification
      as plain English paragraphs. No markdown fences, no code blocks.
  PROMPT

  # Step 2: Generate code from the shaped specification.
  GENERATE_SYSTEM_PROMPT = <<~PROMPT
    You are a Ruby code generator. You MUST respond with ONLY a Ruby method
    definition — nothing else. No explanation, no markdown fences, no comments
    outside the method, no extra text.

    Context for the class you are writing a method for:
    - Class name: %{class_name}
    - Instance variables: %{ivars}
    - Public methods: %{methods}

    Rules:
    - Return exactly one `def method_name ... end` block.
    - Do NOT use system, exec, backticks, File, IO, Kernel, require, load, eval, or send.
    - Do NOT wrap the code in markdown fences.
    - The method must be self-contained.
  PROMPT

  # Generate and install a method via LLM.
  #
  # Two-pass flow:
  #   1. Shape — rewrite the casual user prompt into a precise Ruby method spec
  #   2. Generate — send the shaped spec to the code-generation prompt
  #
  # @param prompt [String] natural-language description of the method to create
  # @param scope  [Symbol] :instance (all instances), :singleton (this object only), or :class
  # @return [Hash] { method_name:, scope:, code:, shaped_prompt:, success: }
  def llm_generate(prompt, scope: :instance)
    # Pass 1: shape the raw prompt into a technical specification
    shaped = llm_self_modify_shape_prompt(prompt, scope)

    unless shaped
      return { method_name: nil, scope: scope, code: nil, shaped_prompt: nil,
               success: false, error: "Prompt shaping failed (LLM returned nil)" }
    end

    # Pass 2: generate code from the shaped specification
    generation_context = llm_self_modify_context
    raw = LlmConfig.ask(shaped, system: generation_context)

    unless raw
      return { method_name: nil, scope: scope, code: nil, shaped_prompt: shaped,
               success: false, error: "Code generation failed (LLM returned nil)" }
    end

    code = llm_self_modify_sanitize(raw)

    begin
      llm_self_modify_validate!(code)
    rescue ArgumentError => e
      return { method_name: nil, scope: scope, code: code, shaped_prompt: shaped,
               success: false, error: e.message }
    end

    method_name = code.match(/\bdef\s+(self\.)?(\w+[?!=]?)/)[2].to_sym

    begin
      llm_self_modify_eval(code, scope)
    rescue => e
      return { method_name: method_name, scope: scope, code: code, shaped_prompt: shaped,
               success: false, error: "eval failed: #{e.message}" }
    end

    on_method_generated(method_name, scope, code)

    { method_name: method_name, scope: scope, code: code, shaped_prompt: shaped, success: true }
  end

  # Override this in your class to persist generated methods.
  def on_method_generated(method_name, scope, code)
    # no-op by default
  end

  private

  # Pass 1: rewrite the user's casual prompt into a precise technical spec.
  def llm_self_modify_shape_prompt(raw_prompt, scope)
    scope_instruction = case scope
    when :instance  then "This will be an instance method available on all instances of the class."
    when :singleton then "This will be a singleton method on one specific object instance only."
    when :class     then "This will be a class method (def self.method_name)."
    end

    shaping_request = <<~REQ
      Rewrite the following casual request into a precise Ruby method specification.

      Class context:
      - Class name: #{self.class.name}
      - Instance variables: #{instance_variables.join(", ")}
      - Public methods: #{(self.class.public_instance_methods(false) - Object.public_instance_methods).sort.join(", ")}
      - Scope: #{scope_instruction}

      User request:
      #{raw_prompt}
    REQ

    LlmConfig.ask(shaping_request, system: SHAPE_SYSTEM_PROMPT)
  end

  # Build the code-generation system prompt with introspected class context.
  def llm_self_modify_context
    format(
      GENERATE_SYSTEM_PROMPT,
      class_name: self.class.name,
      ivars:      instance_variables.join(", "),
      methods:    (self.class.public_instance_methods(false) - Object.public_instance_methods).sort.join(", ")
    )
  end

  # Strip markdown fences and leading/trailing whitespace.
  def llm_self_modify_sanitize(raw)
    text = raw.to_s.strip
    # Remove ```ruby ... ``` or ``` ... ```
    text = text.sub(/\A```\w*\n?/, "").sub(/\n?```\s*\z/, "")
    # Remove <think>...</think> blocks some models produce
    text = text.gsub(/<think>.*?<\/think>/m, "")
    text.strip
  end

  # Validate the sanitized code. Raises ArgumentError on problems.
  def llm_self_modify_validate!(code)
    raise ArgumentError, "code is empty" if code.empty?
    raise ArgumentError, "missing def...end structure" unless code.match?(/\bdef\s+\S+.*?\bend\b/m)
    raise ArgumentError, "dangerous pattern detected" if code.match?(DANGEROUS_PATTERNS)

    # Compile without executing — catches SyntaxError before eval
    RubyVM::InstructionSequence.compile(code)
  rescue SyntaxError => e
    raise ArgumentError, "syntax error: #{e.message}"
  end

  # Evaluate the code inside a sandboxed anonymous module.
  #
  # Each call creates a fresh Module that includes Sandbox, then
  # defines the generated method inside it. The module is then
  # included/extended onto the target so the Sandbox shadows sit
  # between the generated code and Kernel in the MRO.
  def llm_self_modify_eval(code, scope)
    sandbox_mod = Module.new { include LlmSelfModify::Sandbox }

    case scope
    when :instance
      sandbox_mod.module_eval(code)
      self.class.include(sandbox_mod)
    when :singleton
      sandbox_mod.module_eval(code)
      singleton_class.include(sandbox_mod)
    when :class
      # Strip `self.` so the def becomes a regular instance method
      # inside the module; extend then promotes it to a class method.
      class_code = code.sub(/\bdef\s+self\./, "def ")
      sandbox_mod.module_eval(class_code)
      self.class.extend(sandbox_mod)
    else
      raise ArgumentError, "unknown scope: #{scope.inspect}"
    end
  end
end
