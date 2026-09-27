module Finn
  module Tools
    class Calculator < RubyLLM::Tool
      description "Evaluate mathematical expressions: arithmetic, percentages, exponentiation, " \
                  "and common math functions (sqrt, log, log10, exp, sin, cos, tan, pi). " \
                  "Use ^ for exponentiation. Example: '(1500 * 1.07^10) - 1500' or 'sqrt(144)'"

      param :expression, desc: "A math expression, e.g. '(1500 * 1.07^10)', 'sqrt(144)', 'log10(1000)'"

      # Known safe function names that map to Math module methods
      FUNC_NAMES_RE = /\b(sqrt|cbrt|exp|log10|log2|log|sin|cos|tan|pi|PI)\b/.freeze

      FUNC_SUBS = {
        /\bsqrt\b/  => "Math.sqrt",
        /\bcbrt\b/  => "Math.cbrt",
        /\bexp\b/   => "Math.exp",
        /\blog10\b/ => "Math.log10",
        /\blog2\b/  => "Math.log2",
        /\blog\b/   => "Math.log",
        /\bsin\b/   => "Math.sin",
        /\bcos\b/   => "Math.cos",
        /\btan\b/   => "Math.tan",
        /\bpi\b/i   => "Math::PI",
      }.freeze

      # After stripping known function names/constants, only these characters remain
      ALLOWED_CHARS = /\A[\d\s\+\-\*\/\(\)\.]*\z/.freeze

      def execute(expression:)
        expr = expression.strip.gsub(",", "").gsub("^", "**")

        cleaned = expr.gsub(FUNC_NAMES_RE, "").gsub(/\be\b/, "")
        unless cleaned.match?(ALLOWED_CHARS)
          return "Error: Expression contains invalid characters. " \
                 "Allowed: numbers, +, -, *, /, ^, (), and functions: sqrt, log, log10, exp, sin, cos, tan, pi"
        end

        safe_expr = FUNC_SUBS.reduce(expr) { |e, (pat, rep)| e.gsub(pat, rep) }
        safe_expr = safe_expr.gsub(/\be\b/, "Math::E")

        result = eval_expr(safe_expr)

        JSON.generate({
          expression: expression,
          result:     result,
          formatted:  result == result.to_i.to_f ? result.to_i.to_s : result.round(10).to_s,
        })
      rescue ZeroDivisionError
        "Error: Division by zero."
      rescue => e
        "Error evaluating '#{expression}': #{e.message}"
      end

      private

      # Integers are promoted to floats to prevent silent integer division.
      # The lookbehind excludes digits already in a decimal (1.07) and identifiers (log10).
      def eval_expr(expr)
        float_expr = expr.gsub(/(?<![.\d\w])(\d+)(?!\.)/, '\1.0')
        binding.eval(float_expr).to_f
      end
    end
  end
end
