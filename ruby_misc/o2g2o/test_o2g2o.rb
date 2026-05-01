#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick tests for o2g2o conversions

require_relative 'o2g2o'

class O2G2OTest
  def initialize
    @pass = 0
    @fail = 0
  end

  def assert_eq(label, expected, actual)
    if expected == actual
      @pass += 1
      puts "  PASS: #{label}"
    else
      @fail += 1
      puts "  FAIL: #{label}"
      puts "    expected: #{expected.inspect}"
      puts "    actual:   #{actual.inspect}"
    end
  end

  def run
    converter_o2g = O2G2O.new(direction: :o2g)
    converter_g2o = O2G2O.new(direction: :g2o)

    puts "--- Obsidian → GitHub ---"

    assert_eq "simple link",
      "[My Page](my-page.md)",
      converter_o2g.send(:obsidian_to_github, "[[My Page]]")

    assert_eq "link with alias",
      "[click here](my-page.md)",
      converter_o2g.send(:obsidian_to_github, "[[My Page|click here]]")

    assert_eq "link with heading",
      "[My Page#Section One](my-page.md#section-one)",
      converter_o2g.send(:obsidian_to_github, "[[My Page#Section One]]")

    assert_eq "link with heading and alias",
      "[see this](my-page.md#section-one)",
      converter_o2g.send(:obsidian_to_github, "[[My Page#Section One|see this]]")

    assert_eq "same-page anchor",
      "[Section One](#section-one)",
      converter_o2g.send(:obsidian_to_github, "[[#Section One]]")

    assert_eq "image embed",
      "![screenshot](screenshot.png)",
      converter_o2g.send(:obsidian_to_github, "![[screenshot.png]]")

    assert_eq "embed with alt text",
      "![My diagram](diagram.svg)",
      converter_o2g.send(:obsidian_to_github, "![[diagram.svg|My diagram]]")

    assert_eq "multiple links in text",
      "See [Foo](foo.md) and [Bar](bar.md) for details.",
      converter_o2g.send(:obsidian_to_github, "See [[Foo]] and [[Bar]] for details.")

    assert_eq "link in sentence preserves surrounding text",
      "Check out [My Notes](my-notes.md) here.",
      converter_o2g.send(:obsidian_to_github, "Check out [[My Notes]] here.")

    puts ""
    puts "--- GitHub → Obsidian ---"

    assert_eq "simple link",
      "[[My Page]]",
      converter_g2o.send(:github_to_obsidian, "[My Page](my-page.md)")

    assert_eq "link with alias",
      "[[My Page|click here]]",
      converter_g2o.send(:github_to_obsidian, "[click here](my-page.md)")

    assert_eq "link with heading",
      "[[My Page#Section One]]",
      converter_g2o.send(:github_to_obsidian, "[My Page#Section One](my-page.md#section-one)")

    assert_eq "link with heading and alias",
      "[[My Page#Section One|see this]]",
      converter_g2o.send(:github_to_obsidian, "[see this](my-page.md#section-one)")

    assert_eq "image embed",
      "![[screenshot.png]]",
      converter_g2o.send(:github_to_obsidian, "![screenshot](screenshot.png)")

    assert_eq "embed with alt text",
      "![[diagram.svg|My diagram]]",
      converter_g2o.send(:github_to_obsidian, "![My diagram](diagram.svg)")

    assert_eq "ignores external URLs",
      "[Google](https://google.com)",
      converter_g2o.send(:github_to_obsidian, "[Google](https://google.com)")

    assert_eq "multiple links in text",
      "See [[Foo]] and [[Bar]] for details.",
      converter_g2o.send(:github_to_obsidian, "See [Foo](foo.md) and [Bar](bar.md) for details.")

    puts ""
    puts "--- Round-trip ---"

    original_obsidian = "See [[My Page]] and [[Other Page|alias]] and ![[image.png]]"
    round_tripped = converter_g2o.send(
      :github_to_obsidian,
      converter_o2g.send(:obsidian_to_github, original_obsidian)
    )
    assert_eq "obsidian → github → obsidian",
      original_obsidian, round_tripped

    puts ""
    total = @pass + @fail
    puts "#{@pass}/#{total} passed, #{@fail} failed"
    exit(@fail > 0 ? 1 : 0)
  end
end

O2G2OTest.new.run
