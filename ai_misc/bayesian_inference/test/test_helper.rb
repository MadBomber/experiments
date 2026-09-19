# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "bayesian_inference"
require "minitest/autorun"

# Stands in for a RubyLLM chat: returns canned content, records prompts.
# Lets LLM-backed classes be tested with zero network calls.
class FakeChat
  Response = Struct.new(:content)

  attr_reader :last_prompt

  def initialize(content)
    @content = content
  end

  def ask(prompt)
    @last_prompt = prompt
    Response.new(@content)
  end
end
