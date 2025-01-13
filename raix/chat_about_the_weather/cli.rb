require "thor"
require "raix"

module AIChat
  class Cli < Thor
    desc "chat", "Start a chat session with AI"
    def chat
      client = Client.new(
        user_interaction: -> (message, type: :prompt) {
          case type
          when :prompt
            answer = ask(set_color(message, :yellow))
            answer.downcase.start_with?('y')
          when :info
            say(message, :yellow)
            puts
          end
        }
      )
      system_message = <<~PROMPT
        You are a helpful AI assistant. Today's date is #{Time.current.strftime('%B %d, %Y')}.
        You should be direct and concise in your responses while remaining helpful and friendly.
        If you're not sure about something, please say so.
        You have access to several tools - use them when appropriate.
      PROMPT
      client.transcript << { system: system_message }

      say("Welcome to AI Chat!", :green)
      say("Type 'exit' to quit", :yellow)
      puts

      while (input = ask(set_color("You:", :cyan))) != "exit"
        begin
          client.transcript << { user: input }
          results = client.chat_completion(openai: "gpt-4o", loop: true)
          results = Array.wrap(results).flatten

          puts
          say("AI:", :magenta)
          results.each do |result|
            wrapped_text = result.to_s.gsub(/\[.*?\]/, "")
                                    .gsub(/\n+/, "\n")
                                    .strip
            
            say(wrapped_text)
            puts
          end
        rescue => e
          say("Error: Failed to get AI response", :red)
          say("(#{e.message})", :red)
        end
      end
      
      say("Goodbye! Thanks for chatting.", [:green, :bold])
    end
  end
end 