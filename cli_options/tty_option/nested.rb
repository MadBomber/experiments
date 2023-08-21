#!/usr/bin/env ruby
# nested.rb

require "tty-option"

module SQA
  class Command
    include TTY::Option

    header "** DO NOT USE **"
    footer "Another questionable experiment by the MadBomber"

    # banner "== bannder ==" replaces the Usage line

    usage do
      program "sqa"
    end

    flag :force do
      short "-f"
      long "--force"
      desc "Do not prompt for confirmation"
    end

    option :help do
      short "-h"
      long "--help"
      desc "Display help information"
    end

    class << self
      @@commands_available = []

      def names
        '['+ @@commands_available.join('|')+']'
      end

      def inherited(subclass)
        @@commands_available << subclass.to_s.downcase.split('::').last
      end
    end
  end


  class Analysis < Command
    usage do
      program "sqa"
      desc "Connect to a network"
    end

    argument :network

    option :ip do
      long "--ip string"
      desc "IPv4 address (e.g., 172.30.100.104)"
    end
  end

  class Web < Command
    usage do
      program "sqa"
      desc "Disconnect from a network"
    end

    argument :network
  end
end



SQA::Command.command SQA::Command.names

cmd = SQA::Command.new
puts cmd.help

puts

analysis = SQA::Analysis.new
puts analysis.help

puts

web = SQA::Web.new
puts web.help

