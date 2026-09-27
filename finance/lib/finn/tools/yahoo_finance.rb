require "httparty"
require "net/http"
require "uri"
require "json"
require "shellwords"
require "tempfile"

module Finn
  module Tools
    module YahooFinance
      BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

      BASE_HEADERS = {
        "User-Agent"      => BROWSER_UA,
        "Accept"          => "application/json, text/plain, */*",
        "Accept-Language" => "en-US,en;q=0.9",
        "Referer"         => "https://finance.yahoo.com",
        "Origin"          => "https://finance.yahoo.com",
      }.freeze

      COOKIE_TTL = 1_800  # 30 minutes

      # Module-level cookie/crumb cache shared across all tool instances
      @cookie    = nil
      @crumb     = nil
      @auth_at   = nil
      @mutex     = Mutex.new

      class << self
        attr_accessor :cookie, :crumb, :auth_at
        attr_reader   :mutex
      end

      def cookie_and_crumb
        # Manual override: set YF_COOKIE and YF_CRUMB env vars to bypass acquisition
        # (useful during IP-level rate limits or when using an existing browser session).
        if ENV["YF_COOKIE"] && ENV["YF_CRUMB"]
          return [ENV["YF_COOKIE"], ENV["YF_CRUMB"]]
        end

        YahooFinance.mutex.synchronize do
          stale = YahooFinance.auth_at.nil? || Time.now.to_i - YahooFinance.auth_at > COOKIE_TTL
          if stale
            c, cr = acquire_cookie_and_crumb
            YahooFinance.cookie  = c
            YahooFinance.crumb   = cr
            YahooFinance.auth_at = Time.now.to_i
          end
          [YahooFinance.cookie, YahooFinance.crumb]
        end
      end

      def quote_summary(symbol, modules)
        mods    = Array(modules).join(",")
        encoded = URI.encode_uri_component(symbol)
        cookie, crumb = cookie_and_crumb

        response = HTTParty.get(
          "https://query2.finance.yahoo.com/v10/finance/quoteSummary/#{encoded}",
          query:   { modules: mods, formatted: "false", crumb: crumb },
          headers: BASE_HEADERS.merge("Cookie" => cookie),
          timeout: 15
        )

        if response.code == 401 || response.code == 403
          YahooFinance.auth_at = nil  # invalidate cache, retry once
          cookie, crumb = cookie_and_crumb
          response = HTTParty.get(
            "https://query2.finance.yahoo.com/v10/finance/quoteSummary/#{encoded}",
            query:   { modules: mods, formatted: "false", crumb: crumb },
            headers: BASE_HEADERS.merge("Cookie" => cookie),
            timeout: 15
          )
        end

        raise "HTTP #{response.code} from Yahoo Finance" unless response.success?

        body = JSON.parse(response.body)
        err  = body.dig("quoteSummary", "error")
        raise err["description"] if err

        result = body.dig("quoteSummary", "result", 0)
        raise "No data returned for symbol '#{symbol}'" unless result

        result
      end

      def price_chart(symbol, interval: "1d", range: "3mo")
        encoded       = URI.encode_uri_component(symbol)
        cookie, crumb = cookie_and_crumb

        response = HTTParty.get(
          "https://query2.finance.yahoo.com/v8/finance/chart/#{encoded}",
          query:   { interval: interval, range: range, events: "div,splits", crumb: crumb },
          headers: BASE_HEADERS.merge("Cookie" => cookie),
          timeout: 15
        )

        raise "HTTP #{response.code} fetching chart for #{symbol}" unless response.success?

        JSON.parse(response.body)
      end

      def search_news(symbol, count: 10)
        cookie, crumb = cookie_and_crumb

        response = HTTParty.get(
          "https://query2.finance.yahoo.com/v1/finance/search",
          query:   { q: symbol, newsCount: count, enableFuzzyQuery: false, lang: "en-US", crumb: crumb },
          headers: BASE_HEADERS.merge("Cookie" => cookie),
          timeout: 10
        )
        return [] unless response.success?

        JSON.parse(response.body)["news"] || []
      end

      # Handles both {raw: n, fmt: "..."} and plain numeric values
      def raw_value(obj, key)
        return nil unless obj.is_a?(Hash)
        val = obj[key]
        return nil if val.nil?
        val.is_a?(Hash) ? (val["raw"] || val["fmt"]) : val
      end

      def format_large_number(n)
        return "N/A" if n.nil?
        n = n.to_f
        if n.abs >= 1_000_000_000_000
          format("%.2fT", n / 1_000_000_000_000)
        elsif n.abs >= 1_000_000_000
          format("%.2fB", n / 1_000_000_000)
        elsif n.abs >= 1_000_000
          format("%.2fM", n / 1_000_000)
        elsif n.abs >= 1_000
          format("%.2fK", n / 1_000)
        else
          n.round(2).to_s
        end
      end

      def epoch_to_date(ts)
        return "N/A" if ts.nil? || ts.to_i.zero?
        Time.at(ts.to_i).utc.strftime("%Y-%m-%d")
      rescue
        "N/A"
      end

      private

      # Uses curl (always available on macOS) to handle the Yahoo Finance cookie/crumb
      # auth flow reliably. curl's native cookie jar handles redirects and SameSite
      # attributes that pure Net::HTTP misses under rate-limited conditions.
      def acquire_cookie_and_crumb
        cookie_file = Tempfile.new("finn_yf_")
        cookie_path = cookie_file.path
        cookie_file.close

        `curl -s -L \
          -c #{cookie_path.shellescape} \
          -H #{("User-Agent: " + BROWSER_UA).shellescape} \
          -H "Accept: text/html" \
          -H "Accept-Language: en-US,en;q=0.9" \
          "https://finance.yahoo.com/" \
          -o /dev/null 2>&1`

        crumb = `curl -s \
          -b #{cookie_path.shellescape} \
          -H #{("User-Agent: " + BROWSER_UA).shellescape} \
          -H "Accept: text/plain" \
          -H "Accept-Language: en-US,en;q=0.9" \
          -H "Referer: https://finance.yahoo.com" \
          "https://query2.finance.yahoo.com/v1/test/getcrumb" 2>&1`.strip

        raise "Failed to obtain Yahoo Finance crumb: #{crumb}" \
          if crumb.empty? || crumb.include?("Too Many") || crumb.include?("error") || crumb.length > 60

        lines      = File.readlines(cookie_path).reject { |l| l.start_with?("#") || l.strip.empty? }
        cookie_str = lines.filter_map do |line|
          parts = line.chomp.split("\t")
          next if parts.length < 7
          "#{parts[5]}=#{parts[6]}"
        end.join("; ")

        raise "No cookies obtained from Yahoo Finance" if cookie_str.empty?

        [cookie_str, crumb]
      ensure
        File.delete(cookie_path) rescue nil
      end
    end
  end
end
