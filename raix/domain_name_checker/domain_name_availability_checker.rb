# frozen_string_literal: true

module Agents
  class DomainNameAvailabilityChecker
    include Raix::ChatCompletion
    include Raix::FunctionDispatch

    SYSTEM_DIRECTIVE = "Extract suggested domain names from text or JSON. Call the
                        `check_domain_availability` function for each.
                        Do not retry domains that have already been checked."

    attr_accessor :context, :conversation, :domains

    delegate :user_message, to: :context
    delegate :content, to: :user_message

    def initialize(context)
      self.domains = []
      self.model = "openai/gpt-4o-mini"

      transcript << { system: SYSTEM_DIRECTIVE }

      if context.is_a?(String)
        transcript << { user: context }
        self.conversation = "Extract the domain names and check their availability"
      else
        self.context = context
        self.conversation = context.conversation

        transcript << { user: content }
      end
    end

    def call
      chat_completion(loop: true)
      domains
    end

    function :check_domain_availability, "Checks the availability of a domain", domain: { type: "string" } do |arguments|
      if(domain = arguments[:domain].presence)
        DomainAvailabilityChecker.new(domain).call.tap do |result|
          domains[domain] = result
        end
      else
        # either raise an exception or tell the AI to get its act together
        "Error: please provide name of domain to check as `domain` parameter"
      end
    end
  end
end
