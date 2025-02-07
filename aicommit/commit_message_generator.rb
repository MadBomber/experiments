# lib/aicommit_rb/commit_message_generator.rb

require 'ai_client'

require 'debug_me'
include DebugMe

module AicommitRb
  class CommitMessageGenerator
    def initialize(api_key:, model: 'default', max_tokens: 1000)
      # debug_me{[
      #   :api_key,
      #   :max_tokens
      # ]}

      @client = AiClient.new(model, provider: nil)
      @max_tokens = max_tokens
    end

    def generate(diff, style_guide = '')
      prompt = <<~PROMPT
        You are a tool called `aicommit_rb` that generates high-quality commit messages for git diffs.
        Use the following style guide if provided: #{style_guide}
        Limit the subject line to 50 characters.
        Use the imperative mood in the subject line.
        Capitalize the subject line and avoid ending with a period.
        Concisely summarize the main change in the subject line.
        Include a body only if necessary for complex changes.
        Separate body from subject with a blank line if needed.
        Wrap the body at 72 characters.
        Explain the why in the body, not the what.
        Use bullet points in the body for distinct changes.
        Be concise and assume the reader understands the diff.
        Avoid repeating information between the subject and body.
        Do not repeat messages from previous commits.
        Prioritize clarity and brevity.
        Follow the repository's style guide if it exists.
        #{diff}
      PROMPT

      response = @client.chat(prompt)

      debug_me{[
        :prompt,
      ]}

      response
    end
  end
end
