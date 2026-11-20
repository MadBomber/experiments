#!/usr/bin/env ruby
# frozen_string_literal: true

# Logtalk running inside the SWI-Prolog engine embedded in Ruby.
#
# Logtalk is itself a Prolog program, so "embedding Logtalk" is just loading
# it into the embedded engine.  Ruby then sends messages to Logtalk objects,
# and those objects read their data by calling back into Ruby.
#
#   ruby logtalk_demo.rb

require_relative 'swipl'

$stdout.sync = true

# Logtalk finds its files through these two environment variables.  The
# launcher scripts (swilgt and friends) normally set them.
module LogtalkEnv
  HOME_CANDIDATES = ['/opt/homebrew/share/logtalk', '/usr/local/share/logtalk', '/usr/share/logtalk'].freeze

  module_function

  def home = ENV['LOGTALKHOME'] || HOME_CANDIDATES.find { |dir| Dir.exist?(dir) }

  # The per-user directory is optional for running code; fall back to the
  # installation itself when it has not been created.
  def user(home)
    personal = ENV['LOGTALKUSER'] || File.join(Dir.home, 'logtalk')
    Dir.exist?(personal) ? personal : home
  end

  def apply
    logtalk_home = home or raise 'Logtalk installation not found; set LOGTALKHOME'
    ENV['LOGTALKHOME'] = logtalk_home
    ENV['LOGTALKUSER'] = user(logtalk_home)
    File.join(logtalk_home, 'integration', 'logtalk_swi.pl')
  end
end

ROLES  = { ann: :engineer, bob: :intern, cy: :manager }
LEVELS = { wiki: :public, report7: :internal, payroll: :secret }
OWNERS = { report7: :bob }

integration = LogtalkEnv.apply
prolog = Swipl::Engine.instance

prolog.relation(:ruby_role, 2)       { |_user, _role| ROLES.to_a }
prolog.relation(:ruby_classified, 2) { |_doc, _level| LEVELS.to_a }
prolog.relation(:ruby_owns, 2)       { |_user, _doc| OWNERS.map { |doc, user| [user, doc] } }

# Load Logtalk itself, quietly, then the application's objects.
prolog.first('consult(File)', bind: { File: integration.to_sym })
prolog.first('set_logtalk_flag(report, warnings)')
sources = [File.expand_path('../logtalk/policy', __dir__), File.expand_path('ruby_directory', __dir__)]
prolog.first('logtalk_load(Files)', bind: { Files: sources.map(&:to_sym) })

def readers(prolog, policy, doc)
  prolog.first("#{policy}::readers(Doc, Users)", bind: { Doc: doc })[:Users]
end

built_in  = readers(prolog, 'policy(office)', :payroll)
from_ruby = readers(prolog, 'policy(ruby_directory)', :payroll)
ROLES[:bob] = :manager
promoted  = readers(prolog, 'policy(ruby_directory)', :payroll)
locked    = readers(prolog, 'lockdown(ruby_directory)', :payroll)
refused   = begin
  prolog.first('policy(office)::grants(bob, intern, payroll, secret)')
rescue Swipl::PrologError => e
  e.term.args.first
end

puts <<~REPORT
  policy(office), facts in Logtalk:         #{built_in.inspect}
  policy(ruby_directory), facts in Ruby:    #{from_ruby.inspect}
  after bob is promoted in Ruby:            #{promoted.inspect}
  lockdown(ruby_directory):                 #{locked.inspect}
  protected predicate, called from Ruby:    #{refused}
REPORT
