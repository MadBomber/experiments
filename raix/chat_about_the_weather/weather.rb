module Tools
  module Weather
    extend ActiveSupport::Concern

    included do
      function :check_weather, "Check the weather for a location", location: { type: "string" } do |arguments|
        response = if !user_interaction
          "I cannot check the weather without your permission to use the weather API."
        else
          permission = user_interaction.call(
            "Would you like to allow access to the weather API to check the weather in #{arguments[:location]}? (y/n)",
            type: :prompt
          )

          if permission
            # Here you would make the actual weather API call
            "The weather in #{arguments[:location]} is hot and sunny"
          else
            user_interaction.call("Weather API access denied. Cannot proceed.", type: :info)
            "I cannot check the weather without permission to use the weather API."
          end
        end

        { response: response }
      end
    end
  end
end