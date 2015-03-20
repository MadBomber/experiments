# lib/hn_title_generator/markov_model.rb
module HNTitleGenerator

  ##
  # A model to represent all Hacker News titles, and generate sentences using
  # markov chains.
  class MarkovModel
    ##
    # Creates the ultimate buzzword generator using markov chains trained on the
    # titles found in MarkovNews::Item.titles.
    def initialize
      @markov_model = Hash.new { |hash, key| hash[key] = [] }

      Item.each_title do |title|
        tokens = tokenize(title)
        until tokens.empty?
          token = tokens.pop
          markov_state = [tokens[-2], tokens[-1]]
          @markov_model[markov_state] << token
        end
      end
    end

    ##
    # Completes a sentence using the Markov Model trained on news titles.
    #
    # @param [String] sentence to be completed, empty string is acceptable
    # @param [Integer] min_length specifies the lower bound on random sentence
    # length. The sentence may be shorter than this if a punctuation character
    # is encountered.
    # @param [Integer] max_length specifies the upper bound on random sentence
    # length
    # @return [String] a complete sentence according to the markov model
    def complete_sentence(sentence = '', min_length: 5, max_length: 20)
      tokens = tokenize(sentence)
      until sentence_complete?(tokens, min_length, max_length)
        markov_state = [tokens[-2], tokens[-1]]
        tokens << @markov_model[markov_state].sample
      end
      tokens.join(' ').strip
    end

    private
    ##
    # Breaks the sentence into words using spaces. Punctuation is retained as
    # parts of words so that conjunctions and sentence endings retain data.
    #
    # @param [String] sentence to tokenize
    # @return [Array<Symbol>] the tokens in the sentence
    def tokenize(sentence)
      return [] if sentence.nil? || sentence.length == 0

      sentence.split(' ').map { |word| word.downcase.to_sym }
    end

    ##
    # Checks a token list to see if it forms a proper complete sentence
    #
    # @param [Array<symbol>] tokens to consider
    # @param [Integer] minimun length that qualifies a complete sentence
    # @param [Integer] maximum length of any acceptable sentence
    # @return [Boolean] wether the sentence is complete
    def sentence_complete?(tokens, min_length, max_length)
      tokens.length >= max_length || tokens.length >= min_length && (
      tokens.last.nil? || tokens.last =~ /[\!\?\.]\z/
      )
    end
  end
end
