# .../Foo/cli/commands/exec.rb

class Commands::Exec < Commands::Base
  Commands.register "exec", self
  Commands.register "exec version", PrintVersion, aliases: %w[--version]

  desc "Execute a task"

  argument :task,
    type: :string,
    required: true,
    desc: "Task to be executed"

  argument :dirs,
    type: :array,
    required: false,
    desc: "Optional directories"

  option :exit,
    type:     :integer,
    default:  0,
    values:   (0..255).to_a,
    desc:     "exit code",
    aliases:  %w[ -x ]

  def call(task:, dirs: [], **options)
    puts "exec - task: #{task}, dirs: #{dirs.inspect}"
    exit(options[:exit])
  end
end
