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
          validate_and_clean_recommendations(message.payload, bus)
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

    def validate_and_clean_recommendations(payload, bus)
      # First validate quality standards
      validate_recommendations_quality(payload, bus)
      
      # Then clean up department names
      clean_department_names(payload, bus)
    end

    def validate_recommendations_quality(payload, bus)
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

    def clean_department_names(payload, bus)
      return unless payload[:recommendations].is_a?(Array)

      cleaned_count = 0
      name_changes = []

      payload[:recommendations].each do |rec|
        next unless rec[:proposed_name]

        original_name = rec[:proposed_name]
        cleaned_name = sanitize_department_name(original_name)

        if original_name != cleaned_name
          rec[:proposed_name] = cleaned_name
          
          # Also update the implementation file name if present
          if rec[:implementation] && rec[:implementation][:new_config_file]
            rec[:implementation][:new_config_file] = "#{cleaned_name.downcase.gsub(/\s+/, '_')}.yml"
          end
          
          cleaned_count += 1
          name_changes << "#{original_name} → #{cleaned_name}"
        end
      end

      if cleaned_count > 0
        bus.emit VSM::Message.new(
          kind: :policy,
          payload: "Cleaned #{cleaned_count} department names: #{name_changes.join(', ')}"
        )
      end
    end

    def sanitize_department_name(name)
      # Start with the original name
      cleaned = name.dup

      # Replace special characters with word equivalents
      replacements = {
        '&' => 'and',
        '@' => 'at',
        '%' => 'percent',
        '#' => 'number',
        '+' => 'plus',
        '/' => 'or',
        '\\' => 'or'
      }

      replacements.each do |special, replacement|
        cleaned.gsub!(special, " #{replacement} ")
      end

      # Remove any remaining special characters (keeping only letters, numbers, spaces, underscores)
      cleaned.gsub!(/[^a-zA-Z0-9\s_]/, ' ')

      # Clean up whitespace
      cleaned.squeeze!(' ')
      cleaned.strip!

      # Remove trailing "Department" or "department" to prevent duplication
      # when CityCouncil adds "_department" suffix
      cleaned.gsub!(/\s+(Department|department)$/i, '')

      # Also remove any "_department" suffix if present (for snake_case inputs)
      cleaned.gsub!(/_department$/i, '')

      # Ensure proper capitalization for display
      cleaned.split.map(&:capitalize).join(' ')
    end
  end
end