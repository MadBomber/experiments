#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/dictionaries.rb
##  Desc: Word lists shared by prose_score analyzers, sourced from the
##        rubric research (WikiHow, Purdue OWL, Fiveable AP guide,
##        Excellence in Literature, Lumen Learning)
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module Dictionaries
    COORDINATING_CONJUNCTIONS = %w[for and nor but or yet so].freeze

    SUBORDINATING_CONJUNCTIONS = %w[
      although because since unless while when whereas if though
      after before until whenever wherever whether once as
    ].freeze

    RELATIVE_PRONOUNS = %w[who whom whose which that].freeze

    PREPOSITIONS = %w[
      of in on at to from by with about against between into through during
      before after above below over under without within throughout since
      until unless towards upon among across behind beyond despite except
      alongside near off onto per underneath via
    ].freeze

    BE_VERBS = %w[am is are was were be being been].freeze

    MODAL_VERBS = %w[will would shall should can could may might must].freeze

    NEGATION_WORDS = %w[not no never none nobody nothing neither nowhere cannot].freeze

    GENERIC_VERBS = %w[go went gone do did done get got make made put took take].freeze

    VAGUE_NOUNS = %w[thing things stuff].freeze

    VAGUE_QUANTIFIERS = [
      'a lot of', 'lots of', 'a number of', 'various', 'a few',
      'many', 'several', 'some'
    ].freeze

    # phrase => suggested replacement (nil when the fix is "cut it")
    FILLER_PHRASES = {
      'in order to' => 'to',
      'due to the fact that' => 'because',
      'it is important to note that' => nil,
      'at this point in time' => 'now',
      'in the event that' => 'if',
      'for the purpose of' => 'to',
      'with regard to' => 'about',
      'on account of the fact that' => 'because',
      'each and every' => 'each',
      'basic fundamentals' => 'fundamentals',
      'past history' => 'history',
      'true fact' => 'fact',
      'final outcome' => 'outcome',
      'close proximity' => 'proximity',
      'absolutely essential' => 'essential',
      'completely eliminate' => 'eliminate',
      'the reason why is that' => 'because',
      'in spite of the fact that' => 'although'
    }.freeze

    CLICHES = [
      'think outside the box', 'at the end of the day', 'low-hanging fruit',
      'it is what it is', 'time will tell', 'only time will tell',
      'when all is said and done', 'the fact of the matter is',
      'needless to say', 'in this day and age', 'last but not least',
      'few and far between', 'avoid it like the plague', 'dead as a doornail',
      'easier said than done', 'every cloud has a silver lining',
      'in the nick of time', 'the calm before the storm', 'all in all'
    ].freeze

    TRANSITIONS = {
      chronology: %w[before next earlier later during after meanwhile while until then first second
                     finally subsequently],
      comparison: ['also', 'similarly', 'likewise', 'in the same way', 'in the same manner'],
      contrast: ['however', 'but', 'in contrast', 'still', 'yet', 'nevertheless', 'even though',
                 'although', 'on the other hand', 'conversely'],
      clarity: ['for example', 'for instance', 'in other words', 'that is', 'namely'],
      continuation: ['and', 'also', 'moreover', 'additionally', 'furthermore', 'another', 'too',
                     'in addition'],
      consequence: ['as a result', 'therefore', 'for this reason', 'thus', 'consequently', 'hence'],
      conclusion: ['in conclusion', 'in summary', 'to sum up', 'overall', 'ultimately']
    }.freeze

    ALL_TRANSITION_PHRASES = TRANSITIONS.values.flatten.sort_by { |p| -p.length }.freeze

    NOMINALIZATION_SUFFIXES = %w[tion sion ment ance ence ity ism ability].freeze

    # common irregular past participles, for passive-voice detection
    # (regular participles are caught by the "-ed" suffix instead)
    IRREGULAR_PAST_PARTICIPLES = %w[
      written seen taken given known shown thrown grown flown drawn broken
      chosen spoken stolen driven ridden hidden eaten beaten forgotten frozen
      born built sent kept left felt made done said held told found bought
      brought caught taught thought sold understood read put set spread
      cut hit hurt let cost lost meant met paid heard led won swept slept
      dealt bent bound bred burnt lent shot struck stuck sung sunk swum
      torn worn woven wound bitten blown chosen forbidden ridden risen
      shaken sworn thrown withdrawn
    ].freeze

    # function words excluded from content-word overlap / noun-string checks
    STOPWORDS = %w[
      a an the and or but nor for so yet
      of in on at to from by with about against between into through
      during before after above below over under again further then once
      here there when where why how all any both each few more most other
      some such no not only own same so than too very
      i me my myself we our ours ourselves you your yours yourself yourselves
      he him his himself she her hers herself it its itself they them their
      theirs themselves what which who whom this that these those
      am is are was were be been being have has had having do does did doing
      will would shall should can could may might must
      as if
    ].freeze
  end
end
