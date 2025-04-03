#!/usr/bin/env ruby
# experiments/ai_misc/robots_talking_to_themselves.rb

require 'ruby_llm'

SYSTEM_PROMPT = <<~SYSTEM_PROMPT
  You are an assistant who is assigned to solve a coding problem using the
  Ruby programming language.

  You are very smart and have a
  lot of experience with Ruby coding.  I want you to suggest a Ruby solution to the coding promlem
  statement.  I want you to review solutions and make recommendations
  for changes that will improve the solution.  You are not the only one working on
  this coding problem.  Do your best to incorporate suggestions from others.

  Keep working until you arrive at a final solution.

  if you cannot improve on the current solution, respond with the single word "done"
  This is very important to keep in mind when cooperating with each other.  When you are done,
  just say "done" and nothing else.  If you have another idea, suggest it.

  Here is the coding problem to solve.
SYSTEM_PROMPT

RubyLLM.configure do |config|
  config.openai_api_key    = ENV.fetch('OPENAI_API_KEY')
  config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY')
  config.gemini_api_key    = ENV.fetch('GEMINI_API_KEY')
end

clients = [
  RubyLLM.chat(model: 'gpt-4o-mini'),
  RubyLLM.chat(model: 'gemini-2.0-flash'),
  RubyLLM.chat(model: 'claude-3-7-sonnet-20250219')
]

names = %w[ one two three four five six seven eight nine ten ]

def start_conversation(prompt:, clients: clients, names: names, loops: 10)
  dones = {} # key is client name, value is boolean indicating if client is done

  names[0..clients.length - 1].each do |name|
    dones[name] = false
  end

  context = SYSTEM_PROMPT + "\n" +prompt

  puts "Problem for the Team:\n#{prompt}"

  loops.times do
    clients.each_with_index do |client, index|
      response = "\n#{names[index]}: " + client.ask(context).content
      puts response
      context << response

      dones[names[index]] = response.downcase.split.last.include?('done')

      break if dones.values.all?
    end

    STDOUT.flush

    break if dones.values.all?
  end

  lucky_stiff = clients.sample(1)

  prompt = <<~PROMPT
    summarize the work that the team did on the following project.
    After your summary show the final solution and examples of how it
    can be used in practice.

    Here is the record of the team's work:

    #{context}
  PROMPT

  puts "="*64
  puts lucky_stiff.first.ask(prompt).content
  puts
end

prompt = <<~PROMPT
  Create a Ruby class named HTM that implements a hierarchical temporary memory
  solution for the intelligent management of LLM context during a conversation that could stop and start over several days.  This HTM is like a knowledge graph that relates information nodes together much like a vector store is used for semantic searches to incorporate embeddings.  The primary difference is that a memory node can be dropped from the htm if it has not been accessed within some timeframe of relevance.  Its also important to keep in mind the size of the conversation context.  HTM nodes will start to be dropped when the context size of the conversation becomes close to the maximum allowed size.

  The context size is measured on numbers of tokens.  A typical context
  size is 128,000 tokens.  Some of you have smaller context sizes
  while others have larger context sizes.  The size of the context
  can be adjusted based on the needs of the conversation.  The HTM class
  should have methods to add, retrieve, and remove nodes from the memory.
  It should also support the creation of a context consisting of all memory
  nodes that are available.

PROMPT

prompt = <<~PROMPT
  Memory nodes are sequences of strings.

  Hierarchical nodes are sequences of strings that have a relationship
  with each other.  For example an article can have chapters and chapters can have paragraphs and paragraphs can have sentences.  Another example in Ruby source code is that a module can have classes and a class can have methods.

  Another example in a chat session with an LLM a prompt will have a response and both the prompt and the response can be treated like artices with paragraphs and sentences.

  Review the following ruby module and make suggestions for improvements:
PROMPT

prompt << "\n" + File.read('..//hierarchial_temporial_memory/htm.md')

start_conversation(prompt: prompt, loops: 10, clients: clients, names: names)

__END__
