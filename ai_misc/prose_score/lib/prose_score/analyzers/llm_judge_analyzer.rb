#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/analyzers/llm_judge_analyzer.rb
##  Desc: Optional LLM-as-judge pass for the traits no deterministic check
##        can reach -- Ideas/Content, true Organization quality, Voice, and
##        Word Choice -- sourced from the Excellence in Literature 6+1
##        Traits rubric. Runs at temperature 0 against a fixed, anchored
##        rubric prompt so it is as reproducible as an LLM call can be, but
##        it is NOT bit-for-bit deterministic the way the other analyzers
##        are: model updates or provider changes can shift results. This is
##        why it's opt-in rather than part of the default score.
##
##        Defaults to a local Ollama model (gpt-oss:20b), matching the
##        RUBY_LLM_PROVIDER/RUBY_LLM_MODEL/OLLAMA_URL convention already
##        used by actor.rb elsewhere in this project. Override with
##        PROSE_SCORE_LLM_MODEL / PROSE_SCORE_LLM_PROVIDER / OLLAMA_URL, or
##        pass model:/provider:/ollama_url: directly.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'json'

module ProseScore
  module Analyzers
    class LlmJudgeAnalyzer
      SCHEMA = {
        type: 'object',
        properties: {
          ideas_score: {
            type: 'integer',
            description: '0-100. Clear, worthwhile point; interesting, compelling perspective; ideas adequately developed and supported, not just asserted.'
          },
          organization_score: {
            type: 'integer',
            description: '0-100. Structure enhances presentation of the thesis/point; transitions move the reader clearly from idea to idea.'
          },
          voice_score: {
            type: 'integer',
            description: '0-100. An individual, engaging voice appropriate to audience and purpose; not generic or interchangeable.'
          },
          word_choice_score: {
            type: 'integer',
            description: '0-100. Precise, natural, engaging word choice. Vivid is good; reaching for exotic ' \
                         'words just to sound impressive is NOT -- plain, precise language scores as well ' \
                         'as ornate language when it is the right choice.'
          },
          rationale: {
            type: 'string',
            description: '2-4 sentences justifying the four scores above, one clause per trait.'
          }
        },
        required: %w[ideas_score organization_score voice_score word_choice_score rationale],
        additionalProperties: false
      }.freeze

      JUDGE_PROMPT = <<~PROMPT
        You are grading prose against a fixed rubric, not offering general feedback.
        Score each trait strictly on this 0-100 anchor scale:
          90-100 outstanding mastery
          70-89  above average
          50-69  average, meets expectations
          30-49  below average
          0-29   a goal area needing significant work

        IDEAS: strong, easily identified point; interesting, compelling perspective;
        ideas are adequately developed and supported, not just asserted.

        ORGANIZATION: structure enhances the presentation of the thesis/point;
        transitions move the reader clearly from idea to idea.

        VOICE: an individual, engaging voice speaks directly to the reader in a tone
        appropriate to its audience and purpose; not generic or interchangeable.

        WORD CHOICE: words are precise, natural, and convey the intended meaning.
        Vivid and varied vocabulary is good; reaching for obscure or "exotic" words
        just to sound impressive is NOT -- plain, precise language should score as
        well as ornate language when it is the right choice for the passage.

        Score the following text. Return only the requested JSON, no commentary
        outside the schema.

        ---
        %<text>s
        ---
      PROMPT

      # matches the RUBY_LLM_PROVIDER/RUBY_LLM_MODEL/OLLAMA_URL convention
      # already used by actor.rb elsewhere in this project, so one Ollama
      # setup serves both the actors and the scorer
      DEFAULT_PROVIDER = 'ollama'
      DEFAULT_MODEL = 'gpt-oss:20b'
      DEFAULT_OLLAMA_URL = 'http://localhost:11434'

      def self.analyze(text, **) = new(text, **).call

      def initialize(text,
                     model: ENV['PROSE_SCORE_LLM_MODEL'] || ENV['RUBY_LLM_MODEL'] || DEFAULT_MODEL,
                     provider: ENV['PROSE_SCORE_LLM_PROVIDER'] || ENV['RUBY_LLM_PROVIDER'] || DEFAULT_PROVIDER,
                     ollama_url: ENV['OLLAMA_URL'] || DEFAULT_OLLAMA_URL)
        @text = text
        @model = model
        @provider = provider
        @ollama_url = ollama_url
      end

      def call
        require 'ruby_llm'
        configure_ollama! if @provider.to_s == 'ollama'
        response = build_chat.ask(prompt)
        result_from(response)
      rescue StandardError => e
        unavailable_result(e.message)
      end

      private

      def configure_ollama!
        base = @ollama_url.to_s.chomp('/')
        base = "#{base}/v1" unless base.end_with?('/v1')
        RubyLLM.configure { |c| c.ollama_api_base = base }
      end

      def build_chat
        # local Ollama models are never in RubyLLM's static registry, so
        # assume_model_exists skips the registry lookup that would otherwise
        # reject them
        chat = RubyLLM.chat(model: @model, provider: @provider, assume_model_exists: true)
        chat.with_schema(SCHEMA).with_temperature(0)
      end

      def prompt = format(JUDGE_PROMPT, text: @text)

      def result_from(response)
        data = response.content
        data = JSON.parse(data) if data.is_a?(String)
        data = data.transform_keys(&:to_sym)

        scores = {
          ideas: data[:ideas_score].to_f,
          organization: data[:organization_score].to_f,
          voice: data[:voice_score].to_f,
          word_choice: data[:word_choice_score].to_f
        }

        AnalysisResult.new(
          score: scores.values.sum.fdiv(scores.size).round(1),
          issues: [],
          metrics: scores.merge(rationale: data[:rationale], available: true)
        )
      end

      # If the LLM call fails (no credentials, no network, provider error),
      # exclude this component from the composite rather than guessing at a
      # score -- the Scorer checks metrics[:available] before weighting it.
      def unavailable_result(message)
        AnalysisResult.new(
          score: 0.0,
          issues: [Issue.new(category: 'llm_judge_unavailable', message:, excerpt: '')],
          metrics: { available: false }
        )
      end
    end
  end
end
