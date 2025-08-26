# doge_vsm/governance.rb

module DogeVSM
  class Governance < VSM::Governance
    def handle(message, bus:, **opts)
      case message.kind
      when :tool_result
        # Validate tool results meet policy requirements
        if message.meta&.dig(:tool) == 'calculate_similarity'
          validate_similarity_analysis(message.payload, bus)
        elsif message.meta&.dig(:tool) == 'generate_recommendations'
          validate_recommendations(message.payload, bus)
        end
      end

      super
    end

    private

    def validate_similarity_analysis(payload, bus)
      # Ensure minimum quality standards
      if payload[:combinations_found] == 0
        bus.emit VSM::Message.new(
          kind: :policy,
          payload: 'No consolidation opportunities found - consider lowering similarity threshold'
        )
      elsif payload[:combinations_found] > 20
        bus.emit VSM::Message.new(
          kind: :policy,
          payload: 'Too many combinations found - consider raising similarity threshold'
        )
      end
    end

    def validate_recommendations(payload, bus)
      # Ensure recommendations meet quality standards
      low_quality = payload[:recommendations].select do |rec|
        rec[:similarity_score] < 20 || rec[:capabilities][:duplicates_eliminated] == 0
      end

      if low_quality.any?
        bus.emit VSM::Message.new(
          kind: :policy,
          payload: "#{low_quality.length} recommendations may not provide sufficient value"
        )
      end
    end
  end
end