# rake_task_arguments.rb

require 'docopt'

class RakeTaskArguments
  def self.parse(task_name, argument_spec, args)
    arguments = {}

    begin
      args.delete_at(1) if args.length >= 2 and args.second == '--'

      Docopt::docopt(argument_spec, {:argv => args}).each do |key, value|
        arguments[key == "--" ? 'task_name' : key.gsub('--', '')] = value
      end
      ARGV.shift until ARGV.empty?
    rescue Docopt::Exit => e
      abort(e.message)
    end

    return arguments
  end # def self.parse_arguments(task_name, argument_spec, args)
end # class RakeTaskArguments
