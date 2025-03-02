#! /usr/bin/env ruby
# encoding: utf-8
# See: https://gist.github.com/ahoward/6c9dce583ab3607307c18e5b3b539254

require 'script' # in ~/lib/ruby

script do
  tldr <<~____
    NAME
      ai - a unix-style filter for processing input with AI assistance

    TL;DR;
      processes input based on type (code or text) and generates AI-assisted output
  ____

  option :type, value: :required
  env :type, value: :required

  option :task, value: :required
  env :task, value: :required

  run do
    type = params.fetch(:type) { :guess }
    task = params.fetch(:task) { :guess }

    input = input_for(type:, task:)

    prompt = prompt_for(input, type:, task:)

    output = completion_for(prompt, type:, task:)

    $stdout.puts(output)
  end

  def input_for(type: :guess, task: :guess)
    input = ''
    stdin = false

    argv.each do |file|
      if file == '-'
        input << $stdin.read unless stdin
        stdin = true
      else
        input << IO.binread(file)
      end
    end

    if input.empty?
      input << $stdin.read
    end

    input
  end

  def prompt_for(input, type:, task: :guess)
    [].tap do |prompt|

      prompt.concat <<~____
        <SYSTEM>
          - you are the most helpful personal assistant, of all time.
          - you analyze input, and produce output, without ever asking questions.
          - when you do not understand a task, you make your best guess as to what is being asked of you
          - you are a unix style filter, and always produce simple, plaintext, output
          - you understand both code and poetic, short, succinct writing styles
          - you avoid capital letters where practical, and combine seriousness and perfection, with occasional humor
        </SYSTEM>
      ____

      prompt.concat <<~____
        <INSTRUCTIONS>
          - consider the INPUT below

          - IFF it appears to be CODE, then:
            - fix any obvious syntax errors and comment your work
            - fix any obvious bugs errors and comment your work
            - replace any/all #FIXME or #AI comments in the code, with suggested implementations using the style and context of the surrounding code
            - try, as much as possible, to preserve the coding conventions noticed
            - try, as much as possible, to preserve indentation in the output
            - output the new code and, nothing but the new code, including any comments you've added

          - IFF it appears to be WRITING, then:
            - fix any obvious spelling errors, execpt those that seem technical/software related, or intentional
            - fix any duplicate words, or other egregious errors
            - try, as much as possible, to preserve style, tone, and philosophy of the original document
            - document your work with comments
            - output output the new copy and, nothing but the new copy, including any comments you added
        </INSTRUCTIONS>
      ____

      prompt.concat <<~____
        <INPUT>
          #{ input }
        </INPUT>
      ____

    end.join("\n")
  end

  def completion_for(prompt, type: :guess, task: :guess)
    completion = ai_that_shit!(prompt)

    unless type == 'code'
      completion.gsub!(/^```.*$/, '')  # remove code block start tags
      completion.gsub!(/```\s*$/, '')  # remove code block end tags
    end

    completion
  end

  def ai_that_shit!(prompt)
    ai = AI::Mistral
    completion = ai.completion_for(prompt)
  end
end

BEGIN {
  require_relative '../lib/script.rb'
  require_relative '../lib/ai.rb'
}
