#!/usr/bin/env ruby
########################################################
###
## File: test_re2.rb

require 're2'
require "minitest/autorun"

# You can use re2 as a mostly drop-in replacement for Ruby's own Regexp and MatchData classes:

class TestRE2 < Minitest::Test
  def setup
    @r = RE2::Regexp.new('w(\d)(\d+)')
    @m = @r.match("w1234")
  end

  def test_like_regexp
    assert_equal '1', @m[1]
    assert_equal 'w1234', @m.string
    assert_equal 1, @m.begin(1)
    assert_equal 2, @m.end(1)
    assert (@r =~ 'w1234')
    refute (@r =~ 'bob')
    assert_nil @r.match("bob")
  end # def test_like_regexp

  def test_short_cut_class_name
    assert_equal RE2::Regexp, RE2('(\d+)').class
  end

  def test_double_quotes_stink
    assert_equal '(\d+)', RE2('(\d+)').to_s
    assert_equal '(d+)', RE2("(\d+)").to_s
    assert_equal '(\d+)', RE2("(\\d+)").to_s
  end

  def test_named_fields
    r = RE2::Regexp.new('(?P<name>\w+) (?P<age>\d+)')
    m = r.match("Bob 40")
    assert_equal 'Bob', m[:name], 'supports symbol as key to named field'
    assert_equal '40',  m["age"], 'supports string as key to named field'
  end

  def test_re2_has_a_scanner
    re = RE2('(\w+)')
    test_array = %w[ Long live the Republic ]
    test_string = test_array.join(' ')
    scanner = re.scan(test_string)
    x = 0
    scanner.each do |match|
      assert_equal [test_array[x]], match
      x += 1
    end
    scanner.rewind
    enum = scanner.to_enum
    assert_equal [test_array[0]], enum.next
    assert_equal [test_array[1]], enum.next
  end

  # TODO: Add a benchmark against the built-in Regexp

end # class TestRE2 < Minitest::Test

=begin
Features

    Pre-compiling regular expressions with RE2::Regexp.new(re), RE2::Regexp.compile(re) or RE2(re) (including specifying options, e.g. RE2::Regexp.new("pattern", :case_sensitive => false)

    Extracting matches with re2.match(text) (and an exact number of matches with re2.match(text, number_of_matches) such as re2.match("123-234", 2))

    Extracting matches by name (both with strings and symbols)

    Checking for matches with re2 =~ text, re2 === text (for use in case statements) and re2 !~ text

    Incrementally scanning text with re2.scan(text)

    Checking regular expression compilation with re2.ok?, re2.error and re2.error_arg

    Checking regular expression "cost" with re2.program_size

    Checking the options for an expression with re2.options or individually with re2.case_sensitive?

    Performing a single string replacement with pattern.replace(replacement, original)

    Performing a global string replacement with pattern.replace_all(replacement, original)

    Escaping regular expressions with RE2.escape(unquoted) and RE2.quote(unquoted)
=end

