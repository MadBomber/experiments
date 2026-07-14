#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/spell_checker.rb
##  Desc: Thin wrapper around the system `aspell` binary. A naive exact-match
##        lookup against /usr/share/dict/words flags nearly every regular
##        past-tense or plural word as "misspelled" because that word list
##        only contains base forms -- aspell's affix rules handle inflection
##        (and proper nouns) correctly, so it is the only reliable option
##        without vendoring a full dictionary.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'open3'

module ProseScore
  module SpellChecker
    def self.available?
      return @available if defined?(@available)

      @available = system('aspell', '--version', out: File::NULL, err: File::NULL) == true
    end

    # returns one entry per misspelled occurrence (repeats if a typo repeats)
    def self.misspelled(text)
      return [] unless available?

      out, _status = Open3.capture2('aspell', 'list', stdin_data: text)
      out.split("\n")
    rescue Errno::ENOENT
      @available = false
      []
    end
  end
end
