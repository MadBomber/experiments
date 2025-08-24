#!/usr/bin/env ruby
# city_council/cli_port.rb
# CityCouncil CLI Port Component

require_relative '../vsm/lib/vsm'
require 'securerandom'

module CityCouncil
  # CLI Port for testing
  class CLIPort < VSM::Port
    include Common::Logger

    def loop
      puts "\n💬 City Council CLI (type 'help' for commands)"
      session = SecureRandom.uuid

      while (line = $stdin.gets&.chomp)
        case line.downcase
        when 'help'
          show_help
        when 'list'
          list_departments
        when 'exit', 'quit'
          break
        else
          @capsule.bus.emit VSM::Message.new(
            kind: :user,
            payload: line,
            meta: { session_id: session }
          )
        end

        print "> "
      end
    end

    def render_out(msg)
      case msg.kind
      when :assistant
        puts "\n🏛️ Council: #{msg.payload}"
      when :tool_result
        puts "\n🔧 Result: #{msg.payload}"
      end
    end

    private

    def show_help
      puts <<~HELP

        City Council Commands:
        - help: Show this help message
        - list: List all existing departments
        - exit/quit: Exit the CLI
        - Or describe a new department need (e.g., "We need traffic management")

      HELP
    end

    def list_departments
      departments = Dir.glob(File.join(__dir__, '..', '*_department.rb')).map { |f| File.basename(f, '.rb') }
      puts "\n📋 Existing Departments:"
      departments.each { |dept| puts "   - #{dept}" }
    end
  end
end
