# experiments/ai_misc/qroq_ai.rb
# See:https://gist.github.com/ahoward/ac930ab3709710c6ad074aa2917b0fa3?utm_source=rubyai.beehiiv.com&utm_medium=referral&utm_campaign=ruby-ai-news-april-24th-2025

module Ima
  module AI
    def AI.provider
      AI::Groq
    end

    def AI.completion_for(...)
      provider.completion_for(...)
    end

    def AI.parse_json(json, liberally: true)
      if liberally
        AI.json_parse_liberally(json)
      else
        JSON.parse(json)
      end
    end

    def AI.json_parse_liberally(json)
      parse = proc do |json|
        result, errors = nil, []

        begin
          result = JSON.parse(json)
        rescue => error
          errors.push(error)

          begin
            result = RbJSON5.parse(json)
          rescue => error
            errors.push(error)
          end
        end

        {result:, errors:}
      end

      stringbash = proc do |json|
        json.gsub!('```json', '')
        json.gsub!('```', '')
      end

      repair = proc do |json|
        json = AI.fix_json(json)
        {json:}
      end

      parse[json] => result:, errors:
      return result if errors.empty?

      stringbash[json]
      parse[json] => result:, errors:
      return result if errors.empty?

      repair[json] => json:
      parse[json] => result:, errors:
      return result if errors.empty?

      raise errors.last
    end

    def AI.fix_json(json)
      prompt = <<~____
        - the following JSON is broken
        - fix it
        - return the valid json and *only* the valid JSON
        - do NOT wrap the JSON with markdown such as '```json` or '```'

        <JSON>
        #{ json }
        </JSON>
      ____

      AI.completion_for(prompt)
    end

    def AI.count_tokens(*args, padding: 420)
      Util.count_tokens(*args) + padding
    end

    class Groq
      def Groq.api_key
        Ima.cast(
          Ima.setting_for(:groq, :api_key){ ENV.fetch('GROQ_API_KEY') },
          :string
        )
      end

      def Groq.model
        Ima.cast(
          Ima.setting_for(:groq, :model){ 'meta-llama/llama-4-scout-17b-16e-instruct' },
          #Ima.setting_for(:groq, :model){ 'qwen-2.5-coder-32b' },
          :string
        )
      end

      def Groq.timeout
        Ima.cast(
          Ima.setting_for(:groq, :timeout){ 420 },
          :number
        )
      end

      # FIXME
      @@MAX_TOKENS = 128_000
      @@RPM = 60
      @@RATE_LIMTER = RateLimiter.new(name: 'groq', rpm: @@RPM - 1)

      attr_reader :api_key
      attr_reader :model
      attr_reader :timeout

      def initialize(api_key:nil, model:nil, timeout:nil)
        @api_key = api_key || Groq.api_key
        @model = model || Groq.model
        @timeout = timeout || Groq.timeout
      end

      def client_for(**kws)
        args = kws[:client] || {}

        args[:api_key] = (kws[:api_key] || api_key)
        args[:model_id] = (kws[:model_id] || kws[:model] || model)
        args[:timeout] = (kws[:timeout] || timeout)

        ::Groq::Client.new(**args)
      end

      def Groq.instance
        new
      end

      def Groq.completion_for(...)
        instance.completion_for(...)
      end

      def completion_for(*args, **kws, &block)
        client = client_for(**kws)

        system = kws[:system]
        prompt = [kws[:prompt] || args].join("\n").strip

        messages =
          [].tap do |m|
            if Util.present?(system)
              m << {'role' => 'system', 'content' => system.to_s}
            end

            if Util.present?(prompt)
              m << {'role' => 'user', 'content' => prompt.to_s}
            end
          end

        Groq.try_hard do
          Groq.rate_limit do
            client.chat(messages).fetch('content')
          end
        end
      end

      def Groq.rate_limit(&block)
        @@RATE_LIMTER.limit(&block)
      end

      def Groq.try_hard(*args, &block)
        if @try_hard == false
          return block.call
        end

        n = 6
        errors = []
        fatal = [
          RangeError,
          NameError,
          ArgumentError,
          Faraday::BadRequestError,
          Faraday::ClientError
        ]

        n.times do |i|
          begin
            return block.call
          rescue => error
            raise error if fatal.include?(error.class)
            errors.push(error)
            s = (2 ** (i + 2))
            warn "Groq.try_hard: sleep(#{ s }), #{ error.class }[#{ error.message }]"
            sleep(s)
          end
        end

        raise errors.last
      end

      def Groq.try_hard=(try_hard)
        @try_hard = !!try_hard
      end
    end
  end
end
