# frozen_string_literal: true

require "ruby_llm"

# SelfAgency — a standalone mixin that gives any class the ability to
# generate and install methods at runtime via an LLM.
#
# Usage:
#   SelfAgency.configure do |config|
#     config.provider = :ollama
#     config.model    = "qwen3-coder:30b"
#     config.api_base = "http://localhost:11434/v1"
#   end
#
#   class Foo
#     include SelfAgency
#   end
#
#   foo = Foo.new
#   method_name = foo._("an instance method to add two integers, return the result")
#   foo.send(method_name, 1, 1) #=> 2
#
module SelfAgency
  class Error < StandardError; end
  class GenerationError < Error; end
  class ValidationError < Error; end
  class SecurityError   < Error; end

  # ---------------------------------------------------------------------------
  # Configuration
  # ---------------------------------------------------------------------------
  class Configuration
    attr_accessor :provider, :model, :api_base,
                  :request_timeout, :max_retries, :retry_interval

    def initialize
      @provider        = :ollama
      @model           = "qwen3-coder:30b"
      @api_base        = "http://localhost:11434/v1"
      @request_timeout = 30
      @max_retries     = 1
      @retry_interval  = 0.5
    end
  end

  # ---------------------------------------------------------------------------
  # Sandbox — shadows dangerous Kernel methods so generated code cannot
  # call them.  Included in an anonymous module that wraps every generated
  # method, placing these shadows ahead of Kernel in Ruby's MRO.
  # ---------------------------------------------------------------------------
  module Sandbox
    private

    def system(*)  = raise(::SecurityError, "system() blocked by SelfAgency sandbox")
    def exec(*)    = raise(::SecurityError, "exec() blocked by SelfAgency sandbox")
    def spawn(*)   = raise(::SecurityError, "spawn() blocked by SelfAgency sandbox")
    def fork(*)    = raise(::SecurityError, "fork() blocked by SelfAgency sandbox")
    def `(*)       = raise(::SecurityError, "backtick execution blocked by SelfAgency sandbox")
    def open(*)    = raise(::SecurityError, "open() blocked by SelfAgency sandbox")
  end

  # ---------------------------------------------------------------------------
  # Static-analysis patterns that must never appear in generated code
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # LLM system prompts
  # ---------------------------------------------------------------------------

  # Step 1: rewrite a casual prompt into a precise Ruby method specification.
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

  # Step 2: generate code from the shaped specification.
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

  # ---------------------------------------------------------------------------
  # Class-level interface
  # ---------------------------------------------------------------------------
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
      apply_ruby_llm_config!
      configuration
    end

    def reset!
      @configuration = Configuration.new
      @configured = false
    end

    def ensure_configured!
      raise Error, "SelfAgency.configure has not been called" unless @configured
    end

    # When a class does `include SelfAgency`, this callback fires.
    def included(base)
      # nothing extra needed — instance methods are mixed in automatically
    end

    private

    def apply_ruby_llm_config!
      cfg = configuration
      provider_key = :"#{cfg.provider}_api_base"

      RubyLLM.configure do |c|
        c.public_send(:"#{provider_key}=", cfg.api_base) if c.respond_to?(:"#{provider_key}=")
        c.request_timeout = cfg.request_timeout
        c.max_retries     = cfg.max_retries
        c.retry_interval  = cfg.retry_interval
      end

      @configured = true
    end
  end

  # ---------------------------------------------------------------------------
  # Public instance API
  # ---------------------------------------------------------------------------

  # Generate and install a method described by +description+.
  #
  # @param description [String] natural-language description of the method
  # @param scope [Symbol] :instance, :singleton, or :class
  # @return [Symbol] the name of the newly defined method
  # @raise [GenerationError]  if the LLM returns nil
  # @raise [ValidationError]  if the generated code fails validation
  # @raise [SecurityError]    if the generated code contains dangerous patterns
  def _(description, scope: :instance)
    SelfAgency.ensure_configured!

    shaped = self_agency_shape(description, scope)
    raise GenerationError, "Prompt shaping failed (LLM returned nil)" unless shaped

    context = self_agency_generation_context
    raw     = self_agency_ask(shaped, system: context)
    raise GenerationError, "Code generation failed (LLM returned nil)" unless raw

    code = self_agency_sanitize(raw)
    self_agency_validate!(code)

    method_name = code.match(/\bdef\s+(self\.)?(\w+[?!=]?)/)[2].to_sym
    self_agency_eval(code, scope)
    on_method_generated(method_name, scope, code)

    method_name
  end

  # Override in your class to persist or log generated methods.
  def on_method_generated(method_name, scope, code)
    # no-op by default
  end

  # ---------------------------------------------------------------------------
  # Private helpers — all prefixed self_agency_ to avoid collisions
  # ---------------------------------------------------------------------------
  private

  # Send a prompt to the configured LLM.  Returns the response content
  # string, or nil on failure.
  def self_agency_ask(prompt, system: nil)
    cfg  = SelfAgency.configuration
    chat = RubyLLM.chat(model: cfg.model, provider: cfg.provider)
    chat.with_instructions(system) if system
    response = chat.ask(prompt)
    response.content
  rescue => e
    nil
  end

  # Pass 1: rewrite the user's casual prompt into a precise technical spec.
  def self_agency_shape(raw_prompt, scope)
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

    self_agency_ask(shaping_request, system: SHAPE_SYSTEM_PROMPT)
  end

  # Build the code-generation system prompt with introspected class context.
  def self_agency_generation_context
    format(
      GENERATE_SYSTEM_PROMPT,
      class_name: self.class.name,
      ivars:      instance_variables.join(", "),
      methods:    (self.class.public_instance_methods(false) - Object.public_instance_methods).sort.join(", ")
    )
  end

  # Strip markdown fences, <think> blocks, and leading/trailing whitespace.
  def self_agency_sanitize(raw)
    text = raw.to_s.strip
    text = text.sub(/\A```\w*\n?/, "").sub(/\n?```\s*\z/, "")
    text = text.gsub(/<think>.*?<\/think>/m, "")
    text.strip
  end

  # Validate the sanitized code. Raises on problems.
  def self_agency_validate!(code)
    raise ValidationError, "code is empty" if code.empty?
    raise ValidationError, "missing def...end structure" unless code.match?(/\bdef\s+\S+.*?\bend\b/m)
    raise SecurityError, "dangerous pattern detected" if code.match?(DANGEROUS_PATTERNS)

    RubyVM::InstructionSequence.compile(code)
  rescue SyntaxError => e
    raise ValidationError, "syntax error: #{e.message}"
  end

  # Evaluate the code inside a sandboxed anonymous module.
  def self_agency_eval(code, scope)
    sandbox_mod = Module.new { include SelfAgency::Sandbox }

    case scope
    when :instance
      sandbox_mod.module_eval(code)
      self.class.include(sandbox_mod)
    when :singleton
      sandbox_mod.module_eval(code)
      singleton_class.include(sandbox_mod)
    when :class
      class_code = code.sub(/\bdef\s+self\./, "def ")
      sandbox_mod.module_eval(class_code)
      self.class.extend(sandbox_mod)
    else
      raise ValidationError, "unknown scope: #{scope.inspect}"
    end
  end
end
