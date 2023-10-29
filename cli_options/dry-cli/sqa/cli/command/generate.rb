# .../sqa/cli/command/generate.rb

module SQA::CLI::Command::Generate
  def self.prefix
    main_command = nil

    SQA::CLI::Command.register "generate", aliases: ["g"] do |an_object|
      main_command = an_object
    end

    main_command
  end
end
