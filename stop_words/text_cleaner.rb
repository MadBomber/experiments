#!/usr/bin/env ruby
# experiments/stop_words/text_cleaner.rb

require "quick"
require "bm_report"


require "set"


class TextCleaner
  def initialize(file_path:)
    @stoppers_array = File.readlines(file_path).map(&:strip)
    @stoppers_set   = Set.new(@stoppers_array)
  end

  # Use Set to clean the paragraph
  def clean_paragraph_1(text)
    words = text
             .downcase
             .gsub(/[^a-z0-9\s]/, "")
             .split
             .sort

    paragraph_words_set = Set.new(words)

    (paragraph_words_set - @stoppers_set).to_a.join(' ')
  end

  # Use Set to clean the paragraph
  def clean_paragraph_1u(text)
    words = text
             .downcase
             .gsub(/[^a-z0-9\s]/, "")
             .split

    paragraph_words_set = Set.new(words)

    (paragraph_words_set - @stoppers_set).to_a.join(' ')
  end


  # Use Array to clean the 
  # returns cleaned words in sorted order
  def clean_paragraph_2(text)
    words = text
             .downcase
             .gsub(/[^a-z0-9\s]/, "")
             .split
             .sort

    (words - @stoppers_array).join(' ')
  end

  # Use Array to clean the paragraph
  # returns words in given order
  def clean_paragraph_2u(text)
    words = text
             .downcase
             .gsub(/[^a-z0-9\s]/, "")
             .split

    (words - @stoppers_array).join(' ')
  end
end



TC                = TextCleaner.new(file_path: "stop_words_en.srt")
Paragraph         = "This is an example paragraph with some stop words! Like the, and, or."

def bm(how_many=10000)
  one   = quick(how_many, 'set')            { TC.clean_paragraph_1(Paragraph) }
  one_u = quick(how_many, 'set unsorted')   { TC.clean_paragraph_1u(Paragraph) }
  two   = quick(how_many, 'array')          { TC.clean_paragraph_2(Paragraph) }
  two_u = quick(how_many, 'array unsorted') { TC.clean_paragraph_2u(Paragraph) }

  [one, one_u, two, two_u]
end 

bm_report bm

__END__

┌────────┬─────────┬──────────────┬─────────┬────────────────┐
│ Label  │ set     │ set unsorted │ array   │ array unsorted │
├────────┼─────────┼──────────────┼─────────┼────────────────┤
│ cstime │ 0.0     │ 0.0          │ 0.0     │ 0.0            │
│ cutime │ 0.0     │ 0.0          │ 0.0     │ 0.0            │
│ stime  │ 0.02849 │ 0.0218       │ 0.01664 │ 0.01184        │
│ utime  │ 1.28573 │ 1.2954       │ 0.74599 │ 0.78286        │
│ real   │ 1.31511 │ 1.31802      │ 0.76326 │ 0.79635        │
│ total  │ 1.31422 │ 1.31721      │ 0.76263 │ 0.7947         │
└────────┴─────────┴──────────────┴─────────┴────────────────┘
