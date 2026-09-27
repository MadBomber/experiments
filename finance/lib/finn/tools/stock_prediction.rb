module Finn
  module Tools
    class StockPrediction < RubyLLM::Tool
      include YahooFinance

      description "Generate a short-term (5–10 day) directional price prediction for a stock " \
                  "using technical analysis (SMA, RSI, volume trend) with AI reasoning."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"

      def execute(symbol:)
        symbol = symbol.upcase.strip
        chart  = price_chart(symbol, interval: "1d", range: "3mo")

        result_data = chart.dig("chart", "result", 0)
        return "No chart data available for #{symbol}." unless result_data

        quotes  = result_data.dig("indicators", "quote", 0) || {}
        closes  = (quotes["close"]  || []).compact
        volumes = (quotes["volume"] || []).compact

        return "Insufficient price history for technical analysis (need 20+ days)." if closes.length < 20

        indicators = compute_indicators(closes, volumes)

        prediction = llm_predict(symbol, indicators)

        JSON.generate({
          symbol:               symbol,
          technical_indicators: indicators,
          prediction:           prediction,
          disclaimer:           "Technical analysis is for informational purposes only, not financial advice.",
        })
      rescue => e
        "Error generating prediction for #{symbol}: #{e.message}"
      end

      private

      def compute_indicators(closes, volumes)
        last     = closes.last
        sma5     = closes.last(5).sum  / 5.0
        sma20    = closes.last(20).sum / 20.0
        sma50    = closes.length >= 50 ? closes.last(50).sum / 50.0 : nil

        rsi14  = compute_rsi(closes, 14)
        vol5   = volumes.last(5).sum  / 5.0
        vol20  = volumes.last(20).sum / 20.0

        pct_change_5d  = ((last - closes[-6]) / closes[-6] * 100).round(2) rescue nil
        pct_change_20d = ((last - closes[-21]) / closes[-21] * 100).round(2) rescue nil

        {
          current_price:       last.round(4),
          sma_5_day:           sma5.round(4),
          sma_20_day:          sma20.round(4),
          sma_50_day:          sma50&.round(4),
          price_vs_sma5:       last >= sma5  ? "above" : "below",
          price_vs_sma20:      last >= sma20 ? "above" : "below",
          sma5_vs_sma20:       sma5 >= sma20 ? "golden_cross_zone" : "death_cross_zone",
          rsi_14:              rsi14.round(1),
          rsi_signal:          rsi_label(rsi14),
          volume_trend:        vol5 > vol20 * 1.1 ? "increasing" : vol5 < vol20 * 0.9 ? "decreasing" : "stable",
          price_change_5d_pct: pct_change_5d,
          price_change_20d_pct: pct_change_20d,
          data_days:           closes.length,
        }.compact
      end

      def rsi_label(rsi)
        case rsi
        when 0...30   then "oversold (bullish signal)"
        when 30...50  then "below_midline (mild bearish)"
        when 50..70   then "above_midline (mild bullish)"
        when 70..100  then "overbought (bearish signal)"
        else               "neutral"
        end
      end

      def compute_rsi(closes, period = 14)
        return 50.0 if closes.length < period + 1

        changes = closes.each_cons(2).map { |a, b| b - a }
        recent  = changes.last(period)
        gains   = recent.map { |c| c > 0 ? c : 0.0 }
        losses  = recent.map { |c| c < 0 ? c.abs : 0.0 }

        avg_gain = gains.sum / period.to_f
        avg_loss = losses.sum / period.to_f

        return 100.0 if avg_loss.zero?

        rs = avg_gain / avg_loss
        100.0 - (100.0 / (1.0 + rs))
      rescue
        50.0
      end

      def llm_predict(symbol, indicators)
        prompt = <<~PROMPT
          You are a technical analyst. Based on the indicators below for #{symbol}, give a short-term (5–10 trading day) prediction.

          Technical Indicators:
          #{JSON.generate(indicators)}

          Respond with ONLY a JSON object (no markdown, no explanation outside JSON) with these keys:
          - "direction": one of "Bullish", "Bearish", or "Neutral"
          - "confidence": one of "High", "Medium", or "Low"
          - "key_signals": array of 2–3 brief signal descriptions
          - "reasoning": one sentence summary
        PROMPT

        predictor = RubyLLM.chat(model: "claude-haiku-4-5-20251001")
        response  = predictor.ask(prompt)

        json_text = response.content.match(/\{.*\}/m)&.[](0)
        json_text ? JSON.parse(json_text) : { direction: "Neutral", confidence: "Low", reasoning: "Unable to parse prediction." }
      rescue
        { direction: "Neutral", confidence: "Low", reasoning: "Prediction unavailable." }
      end
    end
  end
end
