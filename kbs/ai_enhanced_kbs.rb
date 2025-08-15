#!/usr/bin/env ruby

begin
  require 'ruby_llm'
  require 'ruby_llm/mcp'
rescue LoadError => e
  puts "Warning: #{e.message}"
  puts "Please install: gem install ruby_llm ruby_llm-mcp"
  puts "Continuing with mock AI implementations..."
end

require_relative 'rete2'
require 'json'
require 'date'

module AIEnhancedKBS
  class AIKnowledgeSystem
    def initialize
      @engine = ReteII::ReteEngine.new
      @ai_client = setup_ai_client
      @mcp_agent = setup_mcp_agent
      @sentiment_cache = {}
      @explanation_cache = {}
      setup_ai_enhanced_rules
    end
    
    def setup_ai_client
      if defined?(RubyLLM) && defined?(RubyLLM::Client)
        RubyLLM::Client.new(
          provider: :openai,
          model: 'gpt-4',
          api_key: ENV['OPENAI_API_KEY']
        )
      else
        MockAIClient.new
      end
    end
    
    def setup_mcp_agent
      begin
        if defined?(RubyLLM) && defined?(RubyLLM::MCP) && defined?(RubyLLM::MCP::Agent)
          RubyLLM::MCP::Agent.new(
            name: "market_analyst",
            description: "AI agent for market analysis and trading insights"
          )
        else
          MockMCPAgent.new
        end
      rescue
        MockMCPAgent.new
      end
    end
    
    def setup_ai_enhanced_rules
      # Rule 1: AI-Powered Sentiment Analysis
      sentiment_rule = ReteII::Rule.new(
        "ai_sentiment_analysis",
        conditions: [
          ReteII::Condition.new(:news_data, {
            symbol: ->(s) { s && s.length > 0 },
            headline: ->(h) { h && h.length > 10 },
            content: ->(c) { c && c.length > 50 }
          })
        ],
        action: lambda do |facts, bindings|
          news = facts.find { |f| f.type == :news_data }
          symbol = news[:symbol]
          
          # AI-powered sentiment analysis
          sentiment = analyze_sentiment_with_ai(news[:headline], news[:content])
          
          puts "🤖 AI SENTIMENT ANALYSIS: #{symbol}"
          puts "   Headline: #{news[:headline][0..80]}..."
          puts "   AI Sentiment: #{sentiment[:sentiment]} (#{sentiment[:confidence]}%)"
          puts "   Key Themes: #{sentiment[:themes].join(', ')}"
          puts "   Market Impact: #{sentiment[:market_impact]}"
          
          # Add sentiment fact to working memory
          @engine.add_fact(:ai_sentiment, {
            symbol: symbol,
            sentiment_score: sentiment[:score],
            confidence: sentiment[:confidence],
            themes: sentiment[:themes],
            market_impact: sentiment[:market_impact],
            timestamp: Time.now
          })
        end,
        priority: 20
      )
      
      # Rule 2: AI-Generated Trading Strategy
      ai_strategy_rule = ReteII::Rule.new(
        "ai_strategy_generation",
        conditions: [
          ReteII::Condition.new(:market_conditions, {
            volatility: ->(v) { v && v > 25 },
            trend: ->(t) { t && t.length > 0 }
          }),
          ReteII::Condition.new(:portfolio_state, {
            cash_ratio: ->(c) { c && c > 0.2 }
          })
        ],
        action: lambda do |facts, bindings|
          market = facts.find { |f| f.type == :market_conditions }
          portfolio = facts.find { |f| f.type == :portfolio_state }
          
          # Generate AI strategy
          strategy = generate_ai_trading_strategy(market, portfolio)
          
          puts "🧠 AI TRADING STRATEGY"
          puts "   Market Context: #{market[:trend]} trend, #{market[:volatility]}% volatility"
          puts "   Strategy: #{strategy[:name]}"
          puts "   Rationale: #{strategy[:rationale]}"
          puts "   Actions: #{strategy[:actions].join(', ')}"
          puts "   Risk Level: #{strategy[:risk_level]}"
          
          # Execute AI-suggested actions
          execute_ai_strategy(strategy)
        end,
        priority: 15
      )
      
      # Rule 3: Dynamic Rule Generation
      dynamic_rule_creation = ReteII::Rule.new(
        "dynamic_rule_creation",
        conditions: [
          ReteII::Condition.new(:pattern_anomaly, {
            pattern_type: ->(p) { p && p.length > 0 },
            confidence: ->(c) { c && c > 0.8 },
            occurrences: ->(o) { o && o > 5 }
          })
        ],
        action: lambda do |facts, bindings|
          anomaly = facts.find { |f| f.type == :pattern_anomaly }
          
          # AI generates new trading rule
          new_rule_spec = generate_rule_with_ai(anomaly)
          
          puts "🎯 AI RULE GENERATION"
          puts "   Pattern: #{anomaly[:pattern_type]}"
          puts "   New Rule: #{new_rule_spec[:name]}"
          puts "   Logic: #{new_rule_spec[:description]}"
          
          # Dynamically add new rule to engine
          if new_rule_spec[:valid]
            dynamic_rule = create_rule_from_spec(new_rule_spec)
            @engine.add_rule(dynamic_rule)
            puts "   ✅ Rule added to knowledge base"
          end
        end,
        priority: 12
      )
      
      # Rule 4: AI Risk Assessment
      ai_risk_assessment = ReteII::Rule.new(
        "ai_risk_assessment",
        conditions: [
          ReteII::Condition.new(:position, {
            unrealized_pnl: ->(pnl) { pnl && pnl.abs > 1000 }
          }),
          ReteII::Condition.new(:market_data, {
            symbol: ->(s) { s && s.length > 0 }
          })
        ],
        action: lambda do |facts, bindings|
          position = facts.find { |f| f.type == :position }
          market_data = facts.find { |f| f.type == :market_data }
          
          # AI-powered risk analysis
          risk_analysis = analyze_position_risk_with_ai(position, market_data)
          
          puts "⚠️  AI RISK ASSESSMENT: #{position[:symbol]}"
          puts "   Current P&L: $#{position[:unrealized_pnl]}"
          puts "   Risk Level: #{risk_analysis[:risk_level]}"
          puts "   Key Risks: #{risk_analysis[:risks].join(', ')}"
          puts "   Recommendation: #{risk_analysis[:recommendation]}"
          puts "   Confidence: #{risk_analysis[:confidence]}%"
          
          # Act on high-risk situations
          if risk_analysis[:risk_level] == "HIGH" && risk_analysis[:confidence] > 80
            puts "   🚨 HIGH RISK DETECTED - Consider position adjustment"
          end
        end,
        priority: 18
      )
      
      # Rule 5: Natural Language Explanation Generator
      explanation_rule = ReteII::Rule.new(
        "ai_explanation_generator",
        conditions: [
          ReteII::Condition.new(:trade_recommendation, {
            action: ->(a) { ["BUY", "SELL", "HOLD"].include?(a) },
            symbol: ->(s) { s && s.length > 0 }
          })
        ],
        action: lambda do |facts, bindings|
          recommendation = facts.find { |f| f.type == :trade_recommendation }
          
          # Generate natural language explanation
          explanation = generate_trade_explanation(recommendation, facts)
          
          puts "💬 AI EXPLANATION: #{recommendation[:symbol]} #{recommendation[:action]}"
          puts "   Reasoning: #{explanation[:reasoning]}"
          puts "   Context: #{explanation[:context]}"
          puts "   Confidence: #{explanation[:confidence]}%"
          puts "   Alternative View: #{explanation[:alternative]}"
        end,
        priority: 5
      )
      
      # Rule 6: AI Pattern Recognition
      pattern_recognition_rule = ReteII::Rule.new(
        "ai_pattern_recognition",
        conditions: [
          ReteII::Condition.new(:price_history, {
            symbol: ->(s) { s && s.length > 0 },
            data_points: ->(d) { d && d.length >= 30 }
          })
        ],
        action: lambda do |facts, bindings|
          price_data = facts.find { |f| f.type == :price_history }
          
          # AI identifies patterns
          patterns = identify_patterns_with_ai(price_data[:data_points])
          
          if patterns.any?
            puts "📊 AI PATTERN RECOGNITION: #{price_data[:symbol]}"
            patterns.each do |pattern|
              puts "   Pattern: #{pattern[:name]} (#{pattern[:confidence]}%)"
              puts "   Prediction: #{pattern[:prediction]}"
              puts "   Time Horizon: #{pattern[:time_horizon]}"
            end
          end
        end,
        priority: 10
      )
      
      @engine.add_rule(sentiment_rule)
      @engine.add_rule(ai_strategy_rule)
      @engine.add_rule(dynamic_rule_creation)
      @engine.add_rule(ai_risk_assessment)
      @engine.add_rule(explanation_rule)
      @engine.add_rule(pattern_recognition_rule)
    end
    
    def analyze_sentiment_with_ai(headline, content)
      cache_key = "#{headline[0..50]}_#{content[0..100]}".hash
      return @sentiment_cache[cache_key] if @sentiment_cache[cache_key]
      
      prompt = build_sentiment_prompt(headline, content)
      
      begin
        response = @ai_client.complete(prompt)
        result = parse_sentiment_response(response)
      rescue => e
        puts "AI Error: #{e.message}"
        result = fallback_sentiment_analysis(headline, content)
      end
      
      @sentiment_cache[cache_key] = result
      result
    end
    
    def generate_ai_trading_strategy(market_conditions, portfolio_state)
      prompt = build_strategy_prompt(market_conditions, portfolio_state)
      
      begin
        response = @ai_client.complete(prompt)
        parse_strategy_response(response)
      rescue => e
        puts "AI Error: #{e.message}"
        fallback_strategy_generation(market_conditions, portfolio_state)
      end
    end
    
    def generate_rule_with_ai(anomaly_data)
      prompt = build_rule_generation_prompt(anomaly_data)
      
      begin
        response = @ai_client.complete(prompt)
        parse_rule_specification(response)
      rescue => e
        puts "AI Error: #{e.message}"
        { valid: false, reason: e.message }
      end
    end
    
    def analyze_position_risk_with_ai(position, market_data)
      prompt = build_risk_analysis_prompt(position, market_data)
      
      begin
        response = @ai_client.complete(prompt)
        parse_risk_analysis(response)
      rescue => e
        puts "AI Error: #{e.message}"
        fallback_risk_analysis(position)
      end
    end
    
    def generate_trade_explanation(recommendation, context_facts)
      cache_key = "#{recommendation[:symbol]}_#{recommendation[:action]}_#{context_facts.length}".hash
      return @explanation_cache[cache_key] if @explanation_cache[cache_key]
      
      prompt = build_explanation_prompt(recommendation, context_facts)
      
      begin
        response = @ai_client.complete(prompt)
        result = parse_explanation_response(response)
      rescue => e
        puts "AI Error: #{e.message}"
        result = fallback_explanation(recommendation)
      end
      
      @explanation_cache[cache_key] = result
      result
    end
    
    def identify_patterns_with_ai(price_data)
      prompt = build_pattern_recognition_prompt(price_data)
      
      begin
        response = @ai_client.complete(prompt)
        parse_pattern_response(response)
      rescue => e
        puts "AI Error: #{e.message}"
        []
      end
    end
    
    # Prompt builders
    def build_sentiment_prompt(headline, content)
      <<~PROMPT
        Analyze the sentiment of this financial news for trading implications:
        
        Headline: #{headline}
        Content: #{content[0..500]}...
        
        Provide a JSON response with:
        {
          "sentiment": "positive|negative|neutral",
          "score": -1.0 to 1.0,
          "confidence": 0-100,
          "themes": ["theme1", "theme2"],
          "market_impact": "bullish|bearish|neutral"
        }
      PROMPT
    end
    
    def build_strategy_prompt(market_conditions, portfolio_state)
      <<~PROMPT
        Generate a trading strategy for these conditions:
        
        Market: #{market_conditions[:trend]} trend, #{market_conditions[:volatility]}% volatility
        Portfolio: #{(portfolio_state[:cash_ratio] * 100).round(1)}% cash
        
        Provide a JSON strategy with:
        {
          "name": "strategy_name",
          "rationale": "why this strategy fits",
          "actions": ["action1", "action2"],
          "risk_level": "LOW|MEDIUM|HIGH"
        }
      PROMPT
    end
    
    def build_risk_analysis_prompt(position, market_data)
      <<~PROMPT
        Analyze the risk of this trading position:
        
        Position: #{position[:symbol]}, P&L: $#{position[:unrealized_pnl]}
        Market Data: #{market_data.to_json}
        
        Provide risk assessment as JSON:
        {
          "risk_level": "LOW|MEDIUM|HIGH",
          "risks": ["risk1", "risk2"],
          "recommendation": "hold|reduce|exit",
          "confidence": 0-100
        }
      PROMPT
    end
    
    # Response parsers
    def parse_sentiment_response(response)
      begin
        JSON.parse(response, symbolize_names: true)
      rescue
        fallback_sentiment_analysis("", "")
      end
    end
    
    def parse_strategy_response(response)
      begin
        JSON.parse(response, symbolize_names: true)
      rescue
        {
          name: "Conservative Hold",
          rationale: "Market uncertainty suggests cautious approach",
          actions: ["Monitor positions", "Maintain cash reserves"],
          risk_level: "MEDIUM"
        }
      end
    end
    
    # Fallback implementations
    def fallback_sentiment_analysis(headline, content)
      positive_words = %w[growth profit earnings beat strong bullish rally]
      negative_words = %w[loss decline drop weak bearish crash sell]
      
      text = "#{headline} #{content}".downcase
      positive_count = positive_words.count { |word| text.include?(word) }
      negative_count = negative_words.count { |word| text.include?(word) }
      
      if positive_count > negative_count
        { sentiment: "positive", score: 0.6, confidence: 70, themes: ["earnings"], market_impact: "bullish" }
      elsif negative_count > positive_count
        { sentiment: "negative", score: -0.6, confidence: 70, themes: ["decline"], market_impact: "bearish" }
      else
        { sentiment: "neutral", score: 0.0, confidence: 50, themes: ["mixed"], market_impact: "neutral" }
      end
    end
    
    def fallback_risk_analysis(position)
      pnl = position[:unrealized_pnl]
      
      if pnl < -5000
        { risk_level: "HIGH", risks: ["Large unrealized loss"], recommendation: "review", confidence: 80 }
      elsif pnl > 10000
        { risk_level: "MEDIUM", risks: ["Profit taking opportunity"], recommendation: "hold", confidence: 70 }
      else
        { risk_level: "LOW", risks: ["Normal volatility"], recommendation: "hold", confidence: 60 }
      end
    end
    
    def demonstrate_ai_enhancements
      puts "🤖 AI-ENHANCED KNOWLEDGE-BASED SYSTEM"
      puts "=" * 70
      puts "Integrating #{@ai_client.class.name} and #{@mcp_agent.class.name}"
      puts "=" * 70
      
      # Scenario 1: AI Sentiment Analysis
      puts "\n📰 SCENARIO 1: AI-Powered News Sentiment"
      puts "-" * 50
      @engine.working_memory.facts.clear
      
      @engine.add_fact(:news_data, {
        symbol: "AAPL",
        headline: "Apple Reports Record Q4 Earnings, Beats Expectations by 15%",
        content: "Apple Inc. announced exceptional fourth quarter results today, with revenue growing 12% year-over-year to $94.9 billion. iPhone sales exceeded analysts' expectations, driven by strong demand for the iPhone 15 Pro models. The company also announced a new $90 billion share buyback program and increased its dividend by 4%. CEO Tim Cook expressed optimism about the AI integration roadmap and services growth trajectory.",
        published_at: Time.now
      })
      @engine.run
      
      # Scenario 2: AI Strategy Generation
      puts "\n🧠 SCENARIO 2: AI Trading Strategy Generation"
      puts "-" * 50
      @engine.working_memory.facts.clear
      
      @engine.add_fact(:market_conditions, {
        volatility: 28.5,
        trend: "sideways",
        sector_rotation: "technology_to_healthcare"
      })
      
      @engine.add_fact(:portfolio_state, {
        cash_ratio: 0.25,
        largest_position: "AAPL",
        sector_concentration: 0.45
      })
      @engine.run
      
      # Scenario 3: AI Risk Assessment
      puts "\n⚠️  SCENARIO 3: AI Risk Assessment"
      puts "-" * 50
      @engine.working_memory.facts.clear
      
      @engine.add_fact(:position, {
        symbol: "TSLA",
        shares: 100,
        entry_price: 250.00,
        current_price: 235.00,
        unrealized_pnl: -1500
      })
      
      @engine.add_fact(:market_data, {
        symbol: "TSLA",
        volatility: 45.2,
        beta: 2.1,
        sector: "Consumer Discretionary"
      })
      @engine.run
      
      # Scenario 4: Trade Explanation
      puts "\n💬 SCENARIO 4: AI Trade Explanation"
      puts "-" * 50
      @engine.working_memory.facts.clear
      
      @engine.add_fact(:trade_recommendation, {
        symbol: "GOOGL",
        action: "BUY",
        quantity: 50,
        confidence: 85
      })
      
      @engine.add_fact(:technical_analysis, {
        symbol: "GOOGL",
        rsi: 35,
        moving_average_signal: "golden_cross",
        volume_trend: "increasing"
      })
      @engine.run
      
      puts "\n" + "=" * 70
      puts "AI ENHANCEMENT DEMONSTRATION COMPLETE"
      puts "🎯 The system now combines rule-based logic with AI insights"
      puts "🧠 Dynamic pattern recognition and strategy generation"
      puts "💬 Natural language explanations for all decisions"
      puts "⚡ Real-time sentiment analysis and risk assessment"
    end
  end
  
  # Mock classes for when gems aren't available
  class MockAIClient
    def complete(prompt)
      case prompt
      when /sentiment/i
        '{"sentiment": "positive", "score": 0.7, "confidence": 75, "themes": ["earnings", "growth"], "market_impact": "bullish"}'
      when /strategy/i
        '{"name": "Momentum Strategy", "rationale": "Market showing upward momentum", "actions": ["Buy growth stocks", "Increase position sizes"], "risk_level": "MEDIUM"}'
      when /risk/i
        '{"risk_level": "MEDIUM", "risks": ["Market volatility", "Sector concentration"], "recommendation": "monitor", "confidence": 70}'
      else
        '{"response": "AI analysis complete"}'
      end
    end
  end
  
  class MockMCPAgent
    def analyze(data)
      { analysis: "Mock MCP analysis", confidence: 0.8 }
    end
  end
end

if __FILE__ == $0
  system = AIEnhancedKBS::AIKnowledgeSystem.new
  system.demonstrate_ai_enhancements
end