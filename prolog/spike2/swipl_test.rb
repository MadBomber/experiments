# frozen_string_literal: true

#   ruby swipl_test.rb

require 'minitest/autorun'
require_relative 'swipl'

class InstallTest < Minitest::Test
  def test_parses_runtime_variables
    dump = %(PLBASE="/opt/swipl";\nPLARCH="arm64-darwin";\nPLBITS="64";\n)

    assert_equal({ 'PLBASE' => '/opt/swipl', 'PLARCH' => 'arm64-darwin', 'PLBITS' => '64' },
                 Swipl::Install.parse(dump))
  end
end

class QuoteTest < Minitest::Test
  def test_scalars
    assert_equal '42', Swipl::Quote.term(42)
    assert_equal 'bob', Swipl::Quote.term(:bob)
    assert_equal "'Bob'", Swipl::Quote.term(:Bob)
    assert_equal '"hi"', Swipl::Quote.term('hi')
  end

  def test_quotes_are_escaped
    assert_equal "'it\\'s'", Swipl::Quote.term(:"it's")
    assert_equal '"say \\"hi\\"\\n"', Swipl::Quote.term(%(say "hi"\n))
  end

  def test_structures
    assert_equal '[1,a,[2]]', Swipl::Quote.term([1, :a, [2]])
    assert_equal 'f(a,_)', Swipl::Quote.term(Swipl::Term.new(:f, [:a, Swipl::Var.new('_G1')]))
  end

  def test_rejects_what_prolog_cannot_express
    assert_raises(ArgumentError) { Swipl::Quote.term(nil) }
    assert_raises(ArgumentError) { Swipl::Quote.term(Float::INFINITY) }
    assert_raises(ArgumentError) { Swipl::Quote.variable('lowercase') }
  end
end

class GoalTextTest < Minitest::Test
  def test_goal_is_parenthesised_and_loses_its_period
    assert_equal '(p(X))', Swipl::Engine.goal_text(' p(X). ')
  end

  def test_bindings_come_first
    assert_equal 'X = a, N = 2, (p(X) ; q(N))', Swipl::Engine.goal_text('p(X) ; q(N)', { X: :a, N: 2 })
  end
end

class EngineTest < Minitest::Test
  SOURCE = <<~PROLOG
    p(1). p(2). p(3).
    loop :- loop.
    value(atom).
    value(42).
    value(2.5).
    value("text").
    value(123456789012345678901234567890).
    value(-7).
    value([1, [a, b], []]).
    value(point(1, 2)).
    value(pair(_, _)).
    value([a|_]).
  PROLOG

  # One Prolog per process, so everything is set up once.
  PROLOG = Swipl::Engine.instance.consult(SOURCE, name: 'test_source')
  CALLS = []

  PROLOG.predicate(:big, 1) { |n| n > 1 }
  PROLOG.predicate(:record, 1) { |value| CALLS << value }
  PROLOG.function(:shout, 1) { |text| text.upcase }
  PROLOG.function(:add, 2) { |a, b| a + b }
  PROLOG.function(:describe, 1) { |value| value.class.name }
  PROLOG.function(:boom, 0) { raise ArgumentError, 'from ruby' }
  PROLOG.function(:count_p, 0) { PROLOG.all('p(X)').size }
  PROLOG.function(:squares, 1) { |n| (1..n).map { |i| i * i } }
  PROLOG.relation(:employee, 2) { |_name, _dept| [%i[ann eng], %i[bob ops], %i[cy eng]] }

  def prolog = PROLOG

  # --- queries ------------------------------------------------------------

  def test_all_solutions
    assert_equal [{ X: 1 }, { X: 2 }, { X: 3 }], prolog.all('p(X)')
  end

  def test_failure_yields_nothing
    assert_empty prolog.all('p(99)')
    refute prolog.true?('p(99)')
    assert prolog.true?('p(2)')
  end

  def test_stopping_early_closes_the_query
    200.times { assert_equal({ X: 1 }, prolog.first('p(X)')) }
    assert_equal [{ X: 1 }, { X: 2 }], prolog.query('p(X)').first(2)
  end

  def test_underscore_variables_are_not_reported
    assert_equal [{ X: 1 }], prolog.all('X = 1, _Hidden = 2')
  end

  def test_term_conversion
    values = prolog.all('value(V)').map { |solution| solution[:V] }
    pair, partial = values.pop(2)

    assert_equal [:atom, 42, 2.5, 'text', 123_456_789_012_345_678_901_234_567_890, -7,
                  [1, %i[a b], []], Swipl::Term.new(:point, [1, 2])], values
    assert_equal :pair, pair.functor
    assert(pair.args.all?(Swipl::Var))
    assert_equal :'[|]', partial.functor # a partial list is not an Array
  end

  def test_terms_without_a_ruby_equivalent_are_kept_as_text
    assert_equal Swipl::Opaque.new('1r3'), prolog.first('X is 1 rdiv 3')[:X]
  end

  def test_bind_passes_ruby_values_as_data
    assert_equal({ X: 2 }, prolog.first('p(X)', bind: { X: 2 }))
    assert_equal({ L: [1, :a, 'two'], N: 3 }, prolog.first('length(L, N)', bind: { L: [1, :a, 'two'] }))
  end

  def test_bind_cannot_inject_code
    hostile = :"x'), assertz(p(666)), atom('"
    prolog.first('atom(A)', bind: { A: hostile })

    refute prolog.true?('p(666)')
  end

  def test_round_trip_through_quote
    value = [1, -2.5, :"it's", %(a "quoted"\n\\ string, héllo), [:x, []], Swipl::Term.new(:f, [:a, 1])]

    assert_equal value, prolog.first('X = Y', bind: { Y: value })[:X]
  end

  def test_nested_queries
    pairs = []
    prolog.query('p(X)') do |outer|
      prolog.query('p(Y), Y > X', bind: { X: outer[:X] }) { |inner| pairs << [outer[:X], inner[:Y]] }
    end

    assert_equal [[1, 2], [1, 3], [2, 3]], pairs
  end

  def test_consulting_a_name_again_replaces_its_clauses
    prolog.consult('colour(red).', name: 'colours')
    prolog.consult('colour(blue).', name: 'colours')

    assert_equal [{ C: :blue }], prolog.all('colour(C)')
  end

  def test_constraint_library
    prolog.first('use_module(library(clpfd))')

    assert_equal [{ X: 4 }, { X: 5 }], prolog.all('X #> 3, X #< 6, label([X])')
  end

  # --- errors -------------------------------------------------------------

  def test_prolog_error_becomes_a_ruby_exception
    error = assert_raises(Swipl::PrologError) { prolog.all('X is 1/0') }

    assert_equal Swipl::Term.new(:evaluation_error, [:zero_divisor]), error.term.args.first
    assert_equal 3, prolog.all('p(X)').size
  end

  def test_unknown_predicate
    error = assert_raises(Swipl::PrologError) { prolog.all('no_such_predicate(1)') }

    assert_equal :existence_error, error.term.args.first.functor
  end

  def test_syntax_error
    assert_raises(Swipl::SyntaxError) { prolog.all('p(') }
    assert_equal 3, prolog.all('p(X)').size
  end

  def test_halt_does_not_exit_ruby
    assert_raises(Swipl::Halted) { prolog.all('halt') }
    assert_equal 3, prolog.all('p(X)').size
  end

  def test_timeout_stops_a_runaway_query
    started = Time.now
    assert_raises(Swipl::Timeout) { prolog.all('loop', timeout: 0.2) }

    assert_operator Time.now - started, :<, 2
    assert_equal 3, prolog.all('p(X)', timeout: 5).size
  end

  def test_timeout_while_looking_for_the_next_solution
    seen = []
    assert_raises(Swipl::Timeout) do
      prolog.query('(X = 1 ; loop)', timeout: 0.2) { |solution| seen << solution }
    end

    assert_equal [{ X: 1 }], seen
  end

  def test_other_threads_are_refused
    error = Thread.new { prolog.all('p(X)') rescue $! }.value # rubocop:disable Style/RescueModifier

    assert_kind_of Swipl::Error, error
  end

  # --- callbacks: Prolog calling Ruby --------------------------------------

  def test_predicate_callback_filters_solutions
    assert_equal [{ X: 2 }, { X: 3 }], prolog.all('p(X), big(X)')
  end

  def test_predicate_callback_runs_ruby_side_effects
    CALLS.clear
    prolog.all('p(X), record(seen(X))')

    assert_equal [1, 2, 3].map { |n| Swipl::Term.new(:seen, [n]) }, CALLS
  end

  def test_function_callback_returns_a_value
    assert_equal({ S: 'HI' }, prolog.first('shout("hi", S)'))
    assert_equal({ N: 5 }, prolog.first('add(2, 3, N)'))
    assert_equal({ L: [1, 4, 9] }, prolog.first('squares(3, L)'))
  end

  def test_function_callback_can_check_as_well_as_produce
    assert prolog.true?('add(2, 3, 5)')
    refute prolog.true?('add(2, 3, 6)')
  end

  def test_callback_arguments_arrive_as_ruby_values
    classes = prolog.all('member(V, [1, 2.5, a, "s", [x], f(y), _]), describe(V, C)').map { |s| s[:C] }

    assert_equal %w[Integer Float Symbol String Array Swipl::Term Swipl::Var], classes
  end

  def test_callback_result_feeds_further_prolog
    assert_equal({ L: [1, 4, 9], X: 14 }, prolog.first('squares(3, L), sum_list(L, X)'))
  end

  def test_relation_callback_backtracks_over_ruby_rows
    assert_equal [{ N: :ann }, { N: :cy }], prolog.all('employee(N, eng)')
    assert_equal [{ D: :ops }], prolog.all('employee(bob, D)')
    assert_equal 3, prolog.all('employee(N, D)').size
    refute prolog.true?('employee(zed, _)')
  end

  def test_callback_can_query_prolog_again
    assert_equal({ N: 3 }, prolog.first('count_p(N)'))
  end

  def test_ruby_exception_in_a_callback_resurfaces_in_ruby
    error = assert_raises(ArgumentError) { prolog.all('p(X), boom(Y)') }

    assert_equal 'from ruby', error.message
    assert_equal 3, prolog.all('p(X)').size
  end

  def test_prolog_can_catch_a_ruby_exception
    answer = prolog.first('catch(boom(_), ruby_error(_, Class, Message), true)')

    assert_equal({ Class: :ArgumentError, Message: 'from ruby' }, answer)
  end

  def test_many_callbacks
    assert_equal 50_000, prolog.first('findall(S, (between(1, 50000, N), add(N, 1, S)), L), length(L, Len)')[:Len]
  end
end
