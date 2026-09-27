module Finn
  class Agent
    TOOLS = [
      Finn::Tools::StockPrice,
      Finn::Tools::StockInfo,
      Finn::Tools::IncomeStatement,
      Finn::Tools::BalanceSheet,
      Finn::Tools::CashFlow,
      Finn::Tools::StockDividends,
      Finn::Tools::StockRecommendations,
      Finn::Tools::StockNewsSentiment,
      Finn::Tools::StockPrediction,
      Finn::Tools::CurrencyConverter,
      Finn::Tools::Calculator,
      Finn::Tools::DateTool,
      Finn::Tools::Wikipedia,
      Finn::Tools::WebSearch,
    ].freeze

    def initialize(model: "claude-sonnet-4-6")
      configure_ruby_llm
      @model = model
      @chat  = build_chat
    end

    def ask(input)
      full_input = "#{Finn::Prompts::HUMAN_PREFIX}\n#{input}"
      @chat.ask(full_input)
    end

    def reset
      @chat = build_chat
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"] if ENV["ANTHROPIC_API_KEY"]
        config.openai_api_key    = ENV["OPENAI_API_KEY"]    if ENV["OPENAI_API_KEY"]
      end
    end

    def build_chat
      system_msg = "#{Finn::Prompts::SYSTEM_PROMPT}\n\nToday is #{Time.now.utc.strftime('%A, %B %d, %Y %H:%M UTC')}."

      RubyLLM.chat(model: @model)
        .with_instructions(system_msg)
        .with_tools(*TOOLS)
    end
  end
end
