#!/usr/bin/env ruby
# experiments/ai_misc/coding_agent_with_ruby_llm/agent.rb

require 'require_all'
require 'debug_me'
include DebugMe

$DEBUG_ME = true

require "ruby_llm"

RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
end


# require_relative "tools/read_file"
# require_relative "tools/list_files"
# require_relative "tools/edit_file"
# require_relative "tools/run_shell_command"

tools_dir = "/Users/dewayne/sandbox/git_repos/madbomber/experiments/ai_misc/coding_agent_with_ruby_llm/tools"
# tools_dir = "tools" # also works since it relative to this app's location

require_all "#{tools_dir}/**/*.rb"

class String
  def to_function_name
    self.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        .gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("- ", "_")
        .downcase
        .gsub('/', '--')
  end

  def to_camelcase
    self.gsub('--','/')
        .gsub(/\/(.?)/)   { "::" + $1.upcase }
        .gsub(/(^|_)(.)/) { $2.upcase }
  end
end


class Agent
  def initialize
    @chat = RubyLLM.chat
    # @chat.with_tools(Tools::ReadFile, Tools::ListFiles, Tools::EditFile, Tools::RunShellCommand)

    subclasses = ObjectSpace.each_object(Class).select do |klass|
      klass < RubyLLM::Tool
    end

    @chat.with_tools(*subclasses)


    class_names = subclasses.map(&:name)

    function_names  = class_names.map(&:to_function_name)
    klass_names     = function_names.map(&:to_camelcase)

    debug_me{[
      :subclasses,
      :class_names,
      :function_names,
      :klass_names
    ]}


    allowed_tools = %w[ run_shell_command list_files ]

    filtered_functions = function_names.select do |function_name|
      allowed_tools.any? { |tool| function_name.include?(tool) }
    end

    debug_me{[
      :allowed_tools,
      :filtered_functions
    ]}


  end

  def run
    puts "Chat with the agent. Type 'exit' to ... well, exit"
    loop do
      print "> "
      user_input = gets.chomp
      break if user_input == "exit"

      response = @chat.ask user_input
      puts response.content
    end
  end
end

Agent.new.run
