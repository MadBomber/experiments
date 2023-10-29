# .../sqa/cli/command/base.rb

class SQA::CLI::Command::Base < Dry::CLI::Command
  option :debug,
    type:     :boolean,
    default:  false,
    desc:     'Print debug information'

  option :verbose,
    type:     :boolean,
    default:  false,
    desc:     'Print verbose information'
end
