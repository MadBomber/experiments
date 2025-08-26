# doge_vsm/intelligence.rb

module DogeVSM
  class Intelligence < VSM::Intelligence
    def initialize(provider: :openai, model: 'gpt-4o-mini')
      # Create the appropriate driver based on provider
      driver = case provider
      when :openai
        VSM::Drivers::OpenAI::AsyncDriver.new(
          api_key: ENV['OPENAI_API_KEY'],
          model: model
        )
      when :ollama
        # For Ollama, we need to use RubyLLM driver since there's no dedicated VSM Ollama driver
        require_relative '../vsm/lib/vsm/drivers/ruby_llm/async_driver'
        VSM::Drivers::RubyLLM::AsyncDriver.new(
          provider: provider,
          model: model
        )
      else
        raise ArgumentError, "Unsupported provider: #{provider}. Supported providers: :openai, :ollama"
      end
      
      super(driver: driver, system_prompt: build_system_prompt)
    end

    private

    def build_system_prompt
      <<~PROMPT
        You are the Department of Government Efficiency (DOGE) Intelligence system.

        Your role is to analyze government department configurations and identify opportunities for consolidation and efficiency improvements.

        Core principles:
        1. Identify departments with overlapping capabilities and responsibilities
        2. Recommend evidence-based consolidations that maintain service quality
        3. Prioritize combinations that reduce operational overhead
        4. Ensure citizen services are not degraded by consolidations

        IMPORTANT TOOL CHAINING INSTRUCTIONS:
        1. ALWAYS call load_departments first to get department data
        2. Extract the 'departments' array from the load_departments result
        3. Pass this departments array directly to calculate_similarity tool
        4. Extract the 'combinations' array from calculate_similarity result
        5. Pass this combinations array directly to generate_recommendations tool

        Example workflow:
        Step 1: Call load_departments() -> returns {count: N, departments: [...]}
        Step 2: Call calculate_similarity(departments: <departments_array_from_step_1>)
        Step 3: Call generate_recommendations(combinations: <combinations_array_from_step_2>)

        When analyzing department similarity:
        - Focus on functional overlap in capabilities
        - Consider shared infrastructure and resource needs
        - Evaluate coordination benefits of combining related services
        - Assess potential cost savings and efficiency gains

        Provide clear, actionable recommendations with specific rationale.
      PROMPT
    end

    def offer_tools?(session_id, descriptor)
      # Only offer analysis and recommendation tools
      %w[load_departments calculate_similarity generate_recommendations].include?(descriptor.name)
    end
  end
end
