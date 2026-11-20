#!/usr/bin/env ruby
# frozen_string_literal: true

# Drives two of the demos in ../portable from Ruby.  The Prolog files are
# loaded unchanged except for their `:- initialization(main).` line, which
# would print the answer and halt.
#
#   ruby demo.rb

require_relative 'trealla'

PORTABLE = File.expand_path('../portable', __dir__)

# Each rule file gets its own engine, so their main/0 predicates do not clash.
def load_rules(file)
  source = File.read(File.join(PORTABLE, file)).sub(/^:- initialization\(main\)\.\n/, '')
  Trealla::Engine.new.consult(source, name: file)
end

# A proof is a list of Goal-SubProofs terms; turn it into indented lines.
def proof_lines(proofs, depth = 0)
  proofs.flat_map do |node|
    goal, subproofs = node.args
    ["#{'    ' * depth}#{goal}", *proof_lines(subproofs, depth + 1)]
  end
end

# --- zebra.pl: the solution arrives as Ruby data --------------------------
zebra = load_rules('zebra.pl')
houses = zebra.first('street(Houses)')[:Houses].map(&:args)
zebra_owner = houses.find { |house| house[2] == :zebra }[1]

puts <<~ZEBRA
  zebra.pl
  #{houses.each_with_index.map { |house, i| "  #{i + 1}  #{house.join(', ')}" }.join("\n")}
    => the #{zebra_owner} owns the zebra

ZEBRA

# --- explain.pl: Ruby asks, Prolog decides and says why -------------------
engine = load_rules('explain.pl')

[%i[cy report7], %i[bob payroll]].each do |user, doc|
  answer = engine.first('prove(may_read(User, Doc), Proof)', bind: { User: user, Doc: doc })
  verdict = answer ? "allowed\n#{proof_lines(answer[:Proof], 1).join("\n")}" : 'denied'
  puts "may #{user} read #{doc}?  #{verdict}\n\n"
end

readers = engine.all('may_read(User, payroll)').map { |solution| solution[:User] }
puts "who may read payroll?  #{readers.inspect}"

# --- facts added from Ruby change the answer ------------------------------
engine.first('assertz(owns(User, Doc))', bind: { User: :bob, Doc: :payroll })
readers = engine.all('may_read(User, payroll)').map { |solution| solution[:User] }
puts "after bob is made owner: #{readers.inspect}"

zebra.close
engine.close
