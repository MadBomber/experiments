# doge_vsm/intelligence.rb

module DogeVSM
  class Intelligence < VSM::Intelligence
    def initialize(provider: :openai, model: 'gpt-5-nano')
      driver = VSM::Drivers::RubyLLM::AsyncDriver.new(
        provider: provider,
        model: model
      )
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
