require "date"

module Finn
  module Tools
    class DateTool < RubyLLM::Tool
      description "Parse and format dates. Input can be 'now', 'today', 'yesterday', 'tomorrow', " \
                  "or any date string (e.g. '2024-01-15', 'January 15 2024'). " \
                  "The format parameter uses strftime directives (default: '%A, %B %d, %Y')."

      param :input,  desc: "Date expression: 'now', 'today', 'yesterday', 'tomorrow', or a date string"
      param :format, desc: "strftime format string (default: '%A, %B %d, %Y %H:%M:%S')", required: false

      DEFAULT_FORMAT = "%A, %B %d, %Y %H:%M:%S"

      def execute(input:, format: nil)
        fmt  = format || DEFAULT_FORMAT
        expr = input.to_s.strip.downcase
        time = resolve_time(expr)

        JSON.generate({
          input:          input,
          formatted_date: time.strftime(fmt),
          iso8601:        time.strftime("%Y-%m-%dT%H:%M:%SZ"),
          unix_timestamp: time.to_i,
          day_of_week:    time.strftime("%A"),
        })
      rescue => e
        "Error parsing date '#{input}': #{e.message}"
      end

      private

      def resolve_time(expr)
        case expr
        when "now", "today"
          Time.now.utc
        when "yesterday"
          Time.now.utc - 86_400
        when "tomorrow"
          Time.now.utc + 86_400
        when /\A(\d+)\s+(day|week|month|year)s?\s+ago\z/
          n    = $1.to_i
          unit = $2
          case unit
          when "day"   then Time.now.utc - n * 86_400
          when "week"  then Time.now.utc - n * 604_800
          when "month" then months_ago(n)
          when "year"  then years_ago(n)
          end
        else
          DateTime.parse(expr).to_time.utc
        end
      end

      def months_ago(n)
        t = Time.now.utc
        month = t.month - n
        year  = t.year
        while month < 1
          month += 12
          year  -= 1
        end
        Time.utc(year, month, [t.day, Date.new(year, month, -1).day].min, t.hour, t.min, t.sec)
      end

      def years_ago(n)
        t = Time.now.utc
        Time.utc(t.year - n, t.month, t.day, t.hour, t.min, t.sec)
      end
    end
  end
end
