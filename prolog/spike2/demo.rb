#!/usr/bin/env ruby
# frozen_string_literal: true

# The access policy from ../portable/explain.pl, but with the division of
# labour reversed: Ruby owns the data, Prolog owns the rules.  Prolog reads
# the data by calling back into Ruby, so there is nothing to keep in sync.
#
#   ruby demo.rb

require_relative 'swipl'

$stdout.sync = true

# --- the application's data, in plain Ruby ----------------------------------

ROLES  = { ann: :engineer, bob: :intern, cy: :manager }
LEVELS = { wiki: :public, report7: :internal, payroll: :secret }
OWNERS = { report7: :bob }
AUDIT  = []

# --- the rules, in Prolog ----------------------------------------------------

RULES = <<~PROLOG
  clearance(engineer, internal).
  clearance(manager,  secret).

  covers(Level, Level).
  covers(secret, internal).

  may_read(_User, Doc, public_document)  :- classified(Doc, public).
  may_read(User, Doc, owner)             :- owns(User, Doc).
  may_read(User, Doc, cleared(Role, Level)) :-
      role(User, Role),
      classified(Doc, Level),
      clearance(Role, Cleared),
      covers(Cleared, Level).

  % check/2 decides, and tells Ruby about every decision it makes.
  check(User, Doc) :-
      (   may_read(User, Doc, Why)
      ->  audit(User, Doc, allowed(Why))
      ;   audit(User, Doc, denied),
          fail
      ).
PROLOG

prolog = Swipl::Engine.instance

# Ruby collections that Prolog can backtrack over.
prolog.relation(:role, 2)       { |_user, _role| ROLES.to_a }
prolog.relation(:classified, 2) { |_doc, _level| LEVELS.to_a }
prolog.relation(:owns, 2)       { |_user, _doc| OWNERS.map { |doc, user| [user, doc] } }

# A Ruby side effect that Prolog can trigger.
prolog.predicate(:audit, 3) { |user, doc, outcome| AUDIT << "#{user} -> #{doc}: #{outcome}" }

# A Ruby computation that Prolog can use as a value.
prolog.function(:initials, 1) { |name| name.to_s[0].upcase }

prolog.consult(RULES, name: 'policy')

def readers(prolog, doc)
  prolog.all('role(User, _), check(User, Doc)', bind: { Doc: doc }).map { |answer| answer[:User] }
end

first = readers(prolog, :payroll)
ROLES[:bob] = :manager # promote bob in Ruby; no assert, no reload
second = readers(prolog, :payroll)
labels = prolog.all('role(User, _), initials(User, Initial)').map { |answer| answer[:Initial] }

puts <<~REPORT
  who may read payroll?          #{first.inspect}
  after bob is promoted in Ruby: #{second.inspect}
  initials computed by Ruby:     #{labels.inspect}

  audit log written by Prolog calling Ruby:
  #{AUDIT.map { |line| "  #{line}" }.join("\n")}
REPORT
