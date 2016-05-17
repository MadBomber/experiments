# one.rb
  
desc "Testing parameters with tasks"
task :one, [:params] => :environment do |t, args|

  debug_me{[ :ARGV, :t, :args, :params ]}
  
  # --sites= [(--start-date= --end-date=) | (--days-ago= [--days-ago-end=])]

  # This example fro the github readme does not work within rake because
  # rake look at ARGV entries (even after the --) as rake tasks to be preformed next
  opt_spec = <<-OPTSPEC

  Naval Fate.

  Usage:
    #{t.name} -- ship new <name>...
    #{t.name} -- ship <name> move <x> <y> [--speed=<kn>]
    #{t.name} -- ship shoot <x> <y>
    #{t.name} -- mine (set|remove) <x> <y> [--moored|--drifting]
    #{t.name} -- -h | --help
    #{t.name} -- --version

  Options:
    -h --help     Show this screen.
    --version     Show version.
    --speed=<kn>  Speed in knots [default: 10].
    --moored      Moored (anchored) mine.
    --drifting    Drifting mine.

  OPTSPEC

  parameters = RakeTaskArguments.parse(
    t.name, 
    opt_spec, 
    args[:params].nil? ? ARGV : args[:params]
  )


  ap parameters

end # one


