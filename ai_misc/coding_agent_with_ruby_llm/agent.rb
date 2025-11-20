#!/usr/bin/env ruby
# experiments/ai_misc/coding_agent_with_ruby_llm/agent.rb
# See: https://github.com/radanskoric/coding_agent
# and: https://radanskoric.com/articles/coding-agent-in-ruby

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
  # returns conventional pathname sans extensions
  # for a fully qualified class name
  def to_filename
    self.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        .gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("- ", "_")
        .downcase
  end
end


class Agent
  def initialize
    @chat = RubyLLM.chat

    # Get an Array of fully qualified class names for tools
    # that have been required from the tools_dir
    #
    subclasses = ObjectSpace.each_object(Class).select do |klass|
      klass < RubyLLM::Tool
    end

    # Array of partial filenames for the subclasses that have been
    # loaded.
    #
    allowed_tools = %w[ run_shell_command list_files ]

    filtered_subclasses = subclasses.select do |subclass|
      allowed_tools.any? do |tool|
        subclass.name.to_filename.include?(tool)
      end
    end

    debug_me{[
      :allowed_tools,
      :filtered_subclasses
    ]}

    # What this shows is that its possible to have a CLI option
    # that identifies a tools directory and all of the Ruby files
    # under that directory can be loaded (eg required)
    # ... and then you can use the --allowed_tools option to
    # specify parts of the filenames for only the tools that you
    # want to use.
    # ... OR you can use the --rq (--require) option to require
    # each tool file one at a time.
    # ... AND maybe aia needs a --reject_tools option to reject
    # specific set of tool names while using the tools_dir to load everything.

    @chat.with_tools(*filtered_subclasses)
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
