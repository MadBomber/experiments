# .../sqa/cli/command/exec.rb

module SQA::CLI::Command
class Exec < Base
  SQA::CLI::Command.register "exec", self

  desc "Execute a task"

  argument :task, type: :string, required: true,  desc: "Task to be executed"
  argument :dirs, type: :array,  required: false, desc: "Optional directories"

  def call(task:, dirs: [], **options)
    debug_me{[ :options ]}
    puts "exec - task: #{task}, dirs: #{dirs.inspect}"
  end
end
end