# experiments/raix/assistant.rb
# See: https://gist.github.com/marckohlbrugge/bf424c8e32a7bd54b63cb2e12006b586

# Add these gems to your Gemfile
# gem "rails" # not strictly needed, but I use ActiveConcern, etc
# gem "raix" # helpful gem to reduce code needed for function calling etc 
# gem "thor" # to make a CLI app (not needed if you make a web app)
# gem "http" # my preferred gem to make API calls

# This is the main app (`app/models/ai_chat/cli.rb`)
module AIChat
  class Cli
    # Thor
    include Thor::Base
    include Thor::Shell

    # Raix
    include Raix::ChatCompletion
    include Raix::FunctionDispatch

    # Tools – you can make your own and add here
    include Tools::Weather
    include Tools::AppleScript
    include Tools::Web

    SYSTEM_MESSAGE_TEMPLATE = <<~PROMPT.freeze
      You are a helpful AI assistant. Today's date is %{date}.
      You should be direct and concise in your responses while remaining helpful and friendly.
      If you're not sure about something, please say so.

      # Tools
      You have access to several tools - use them when appropriate.
      You can use the AppleScript tool to run AppleScripts on the user's Mac. This can be used to automate tasks on the user's Mac.
    PROMPT

    attr_reader :transcript

    def initialize
      @transcript = []
      transcript << { system: format(SYSTEM_MESSAGE_TEMPLATE, date: Time.current.strftime('%B %d, %Y')) }
    end

    def start
      say("Welcome to AI Chat!", :green)
      say("Type 'exit' to quit", :yellow)
      puts

      while true
        input = ask("You:", :cyan)
        break if input == "exit"

        transcript << { user: input }
        response = chat_completion(openai: "gpt-4o-mini", loop: true)
        
        say("AI: #{format_response(response)}", :magenta)
      end

      say("Goodbye! Thanks for chatting.", [:green, :bold])
    end

    private

    def format_response(response)
      Array.wrap(response).join("\n\n").strip
    end
  end
end

# Example of a tool (`app/models/tools/weather.rb`)
# It gets triggered by the AI. THen we run the block of code defined by the function.
# The return value of this block is what's sent to the AI. The AI can then use this to
# formulate a more informed response to the user.
#
# In this example we're first asking the user for confirmation to allow access to a fictious weather API.
# In practice, for non-destructive API calls like weather APIs, you probably don't need to have this confirmation
# step and can remove the the answer/ask stuff and immediately make the API call and return it to the AI. 
module Tools
  module Weather
    extend ActiveSupport::Concern

    included do
      function :check_weather, "Check the weather for a location", location: { type: "string" } do |arguments|
        location = arguments[:location]

        answer = ask("Would you like to allow access to the weather API to check the weather in #{location}? (y/n)", :yellow)
        if answer.downcase.start_with?('y')
          say("Retrieved weather for #{location}", :green)
          { response: "The weather in #{location} is hot and sunny" }
        else
          say("Weather API access denied.", :red)
          { response: "Weather check cancelled - permission denied." }
        end
      end
    end
  end
end

# app/models/tools/apple_script.rb
require 'open3'

module Tools
  module AppleScript
    extend ActiveSupport::Concern

    included do
      function :run_apple_script, "Run an AppleScript on the user's Mac", script: { type: "string" } do |arguments|
        say("AI wants to execute the following AppleScript:", :yellow)
        say(arguments[:script], :cyan)

        answer = ask("Would you like to allow this? (y/n)", :yellow)
        if answer.downcase.start_with?("y")
          say("Running AppleScript…", :yellow)
          
          Tempfile.create(['ai_chat_script', '.scpt']) do |f|
            f.write(arguments[:script])
            f.flush
            
            output, error, status = Open3.capture3('osascript', f.path)
            if status.success?
              { response: output.presence || "Script executed successfully" }
            else
              { response: "Error executing AppleScript: #{error}" }
            end
          end
        else
          say("AppleScript access denied.", :red)
          { response: "AppleScript access denied." }
        end
      end
    end
  end
end

# Provides search and fetches webpages. Powered by Jina.ai (`app/models/tool/web.rb`)
module Tools
  module Web
    extend ActiveSupport::Concern

    included do
      function :search_web, "Search the web for information", query: { type: "string" } do |arguments|
        say("Searching the web for '#{arguments[:query]}'…", :yellow)

        response = jina_client.get("https://s.jina.ai/#{CGI.escape(arguments[:query])}")
        
        result = if response.status.success?
          response.body.to_s
        else
          "Sorry, the search failed with status #{response.status}"
        end

        { response: result }
      end
  
      function :fetch_web_page, "Fetch a web page", url: { type: "string" } do |arguments|
        say("Fetching web page '#{arguments[:url]}'…", :yellow)
        response = jina_client.get("https://r.jina.ai/#{CGI.escape(arguments[:url])}")
        
        result = if response.status.success?
          response.body.to_s
        else
          "Sorry, the web page fetch failed with status #{response.status}"
        end

        { response: result }
      end

      private

      def jina_client
        @jina_client ||= HTTP.auth("Bearer #{jina_api_key}")
      end

      def jina_api_key
        "GET THIS FROM JINA.AI"
      end
    end
  end
end
