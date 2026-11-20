# frozen_string_literal: true

#   ruby trealla_test.rb

require 'minitest/autorun'
require_relative 'trealla'

class QuoteTest < Minitest::Test
  def test_scalars
    assert_equal '42', Trealla::Quote.term(42)
    assert_equal '-1.5', Trealla::Quote.term(-1.5)
    assert_equal 'bob', Trealla::Quote.term(:bob)
    assert_equal "'Bob'", Trealla::Quote.term(:Bob)
    assert_equal "'two words'", Trealla::Quote.term(:'two words')
    assert_equal "'[]'", Trealla::Quote.term(:'[]')
    assert_equal '"hi"', Trealla::Quote.term('hi')
  end

  def test_quotes_are_escaped
    assert_equal "'it\\'s'", Trealla::Quote.term(:"it's")
    assert_equal '"say \\"hi\\"\\n"', Trealla::Quote.term(%(say "hi"\n))
  end

  def test_structures
    assert_equal '[1,a,[2]]', Trealla::Quote.term([1, :a, [2]])
    assert_equal 'f(a,X)', Trealla::Quote.term(Trealla::Term.new(:f, [:a, Trealla::Var.new('X')]))
  end

  def test_rejects_what_prolog_cannot_express
    assert_raises(ArgumentError) { Trealla::Quote.term(nil) }
    assert_raises(ArgumentError) { Trealla::Quote.term(Float::NAN) }
    assert_raises(ArgumentError) { Trealla::Quote.variable('lowercase') }
  end
end

class WrapTest < Minitest::Test
  def test_wraps_goal_in_catch_and_drops_the_period
    assert_equal 'catch((p(X)), TreallaRubyError, true).', Trealla::Engine.wrap(' p(X). ')
  end

  def test_bindings_come_first
    assert_equal 'catch((X = a, p(X)), TreallaRubyError, true).', Trealla::Engine.wrap('p(X)', { X: :a })
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

  def setup
    @engine = Trealla::Engine.new.consult(SOURCE, name: 'test')
  end

  def teardown
    @engine.close
  end

  def test_all_solutions
    assert_equal [{ X: 1 }, { X: 2 }, { X: 3 }], @engine.all('p(X)')
  end

  def test_failure_yields_nothing
    assert_empty @engine.all('p(99)')
    refute @engine.true?('p(99)')
    assert @engine.true?('p(2)')
  end

  def test_a_goal_with_no_variables_succeeds_with_an_empty_hash
    assert_equal [{}], @engine.all('p(1)')
  end

  def test_stopping_early_releases_the_query
    200.times { assert_equal({ X: 1 }, @engine.first('p(X)')) }
    assert_equal [{ X: 1 }, { X: 2 }], @engine.query('p(X)').first(2)
  end

  def test_term_conversion
    values = @engine.all('value(V)').map { |solution| solution[:V] }
    pair, partial = values.pop(2)

    assert_equal [:atom, 42, 2.5, 'text', 123_456_789_012_345_678_901_234_567_890, -7,
                  [1, %i[a b], []], Trealla::Term.new(:point, [1, 2])], values
    assert_equal :pair, pair.functor
    assert(pair.args.all?(Trealla::Var))
    assert_equal :'.', partial.functor # a partial list is not an Array
  end

  def test_unbound_variable
    assert_kind_of Trealla::Var, @engine.first('X = Y')[:X]
  end

  def test_bind_passes_ruby_values_as_data
    assert_equal({ X: 2 }, @engine.first('p(X)', bind: { X: 2 }))
    assert_equal({ L: [1, :a, 'two'], N: 3 }, @engine.first('length(L, N)', bind: { L: [1, :a, 'two'] }))
  end

  def test_bind_cannot_inject_code
    hostile = :"x'), assertz(p(666)), atom('"
    @engine.first('atom(A)', bind: { A: hostile })

    refute @engine.true?('p(666)')
    assert_equal hostile, @engine.first('A = B', bind: { B: hostile })[:A]
  end

  def test_round_trip_through_quote
    value = [1, -2.5, :"it's", %(a "quoted"\n\\ string), [:x, []], Trealla::Term.new(:f, [:a, 1])]

    assert_equal value, @engine.first('X = Y', bind: { Y: value })[:X]
  end

  def test_prolog_error_becomes_a_ruby_exception
    error = assert_raises(Trealla::PrologError) { @engine.all('X is 1/0') }

    assert_equal :error, error.term.functor
    assert_equal Trealla::Term.new(:evaluation_error, [:zero_divisor]), error.term.args.first
  end

  def test_unknown_predicate_is_a_prolog_error
    error = assert_raises(Trealla::PrologError) { @engine.all('no_such_predicate(1)') }

    assert_equal :existence_error, error.term.args.first.functor
  end

  def test_engine_survives_an_error
    assert_raises(Trealla::PrologError) { @engine.all('X is foo + 1') }
    assert_equal 3, @engine.all('p(X)').size
  end

  def test_syntax_error
    assert_raises(Trealla::SyntaxError) { @engine.all('p(') }
    assert_equal 3, @engine.all('p(X)').size
  end

  def test_timeout_stops_a_runaway_query
    started = Time.now
    assert_raises(Trealla::Timeout) { @engine.all('loop', timeout: 0.2) }

    assert_operator Time.now - started, :<, 2
    assert_equal 3, @engine.all('p(X)').size
  end

  def test_timeout_does_not_disturb_a_fast_query
    assert_equal 3, @engine.all('p(X)', timeout: 5).size
  end

  def test_timeout_while_looking_for_the_next_solution
    seen = []
    assert_raises(Trealla::Timeout) do
      @engine.query('(X = 1 ; loop)', timeout: 0.2) { |solution| seen << solution }
    end

    assert_equal [{ X: 1 }], seen
    assert_equal 3, @engine.all('p(X)').size
  end

  def test_nested_queries_on_one_engine
    pairs = []
    @engine.query('p(X)') do |outer|
      @engine.query('p(Y), Y > X', bind: { X: outer[:X] }) { |inner| pairs << [outer[:X], inner[:Y]] }
    end

    assert_equal [[1, 2], [1, 3], [2, 3]], pairs
  end

  def test_engines_are_independent
    other = Trealla::Engine.new.consult('p(other).')

    assert_equal [{ X: :other }], other.all('p(X)')
    assert_equal 3, @engine.all('p(X)').size
  ensure
    other&.close
  end

  def test_assert_persists_between_queries
    @engine.first('assertz(seen(ruby))')

    assert_equal({ W: :ruby }, @engine.first('seen(W)'))
  end

  def test_other_ruby_threads_run_during_a_query
    ticks = 0
    ticker = Thread.new { loop { sleep 0.005; ticks += 1 } }
    assert_raises(Trealla::Timeout) { @engine.all('loop', timeout: 0.3) }
    ticker.kill

    assert_operator ticks, :>, 10
  end

  def test_constraint_library_is_available
    @engine.first('use_module(library(clpz))')

    assert_equal [{ X: 4 }, { X: 5 }], @engine.all('X #> 3, X #< 6, label([X])')
  end
end
