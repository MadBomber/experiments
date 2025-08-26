# doge_vsm/operations/similarity_calculator_tool.rb

module DogeVSM
  class Operations < VSM::Operations
    class SimilarityCalculatorTool < VSM::ToolCapsule
      tool_name 'calculate_similarity'
      tool_description 'Calculate similarity scores between departments'
      tool_schema({
        type: 'object',
        properties: {
          departments: { 
            type: 'array', 
            description: 'Array of department objects',
            items: {
              type: 'object',
              properties: {
                name: { type: 'string' },
                description: { type: 'string' },
                keywords: { type: 'array', items: { type: 'string' } },
                capabilities: { type: 'array', items: { type: 'string' } },
                message_types: { type: 'object' }
              }
            }
          },
          threshold: { type: 'number', description: 'Minimum similarity threshold (default: 0.15)' }
        },
        required: ['departments']
      })

      def run(args)
        begin
          # Handle both direct array and wrapped format from LoadDepartmentsTool
          # Handle both symbol and string keys from different AI models
          departments_data = args[:departments] || args["departments"]
          
          if departments_data.is_a?(Hash) && departments_data[:departments]
            departments = departments_data[:departments]
          elsif departments_data.is_a?(Array)
            departments = departments_data
          else
            return { error: "Invalid departments data format: #{departments_data.class}" }
          end

          return { error: "No departments provided" } if departments.nil? || departments.empty?
          
          threshold = args[:threshold] || 0.05  # Lowered threshold to 5% to find meaningful combinations
        combinations = []

        departments.each_with_index do |dept1, i|
          departments.each_with_index do |dept2, j|
            next if i >= j  # Avoid duplicate comparisons

            similarity_score = calculate_department_similarity(dept1, dept2)

            if similarity_score >= threshold
              combinations << {
                dept1: dept1,
                dept2: dept2,
                score: similarity_score,
                reasons: analyze_similarity_reasons(dept1, dept2)
              }
            end
          end
        end

          sorted_combinations = combinations.sort_by { |combo| -combo[:score] }
          
          {
            threshold: threshold,
            combinations_found: combinations.length,
            combinations: sorted_combinations
          }
        rescue => e
          { error: "Similarity calculation error: #{e.class}: #{e.message}" }
        end
      end

      private

      def calculate_department_similarity(dept1, dept2)
        scores = []

        # Handle both symbol and string keys
        keywords1 = dept1[:keywords] || dept1["keywords"] || []
        keywords2 = dept2[:keywords] || dept2["keywords"] || []
        capabilities1 = dept1[:capabilities] || dept1["capabilities"] || []
        capabilities2 = dept2[:capabilities] || dept2["capabilities"] || []
        description1 = dept1[:description] || dept1["description"] || ""
        description2 = dept2[:description] || dept2["description"] || ""
        message_types1 = dept1[:message_types] || dept1["message_types"] || {}
        message_types2 = dept2[:message_types] || dept2["message_types"] || {}

        # Keyword overlap (40% weight)
        keyword_similarity = calculate_keyword_similarity(keywords1, keywords2)
        scores << keyword_similarity * 0.4

        # Capability overlap (30% weight)
        capability_similarity = calculate_capability_similarity(capabilities1, capabilities2)
        scores << capability_similarity * 0.3

        # Description similarity (20% weight)
        description_similarity = calculate_description_similarity(description1, description2)
        scores << description_similarity * 0.2

        # Message type overlap (10% weight)
        message_similarity = calculate_message_type_similarity(message_types1, message_types2)
        scores << message_similarity * 0.1

        scores.sum
      end

      def calculate_keyword_similarity(keywords1, keywords2)
        return 0.0 if keywords1.empty? || keywords2.empty?

        intersection = Set.new(keywords1) & Set.new(keywords2)
        union = Set.new(keywords1) | Set.new(keywords2)

        return 0.0 if union.empty?
        intersection.size.to_f / union.size.to_f
      end

      def calculate_capability_similarity(capabilities1, capabilities2)
        return 0.0 if capabilities1.empty? || capabilities2.empty?

        words1 = Set.new(capabilities1.join(' ').downcase.scan(/\w+/).select { |w| w.length > 3 })
        words2 = Set.new(capabilities2.join(' ').downcase.scan(/\w+/).select { |w| w.length > 3 })

        return 0.0 if words1.empty? || words2.empty?

        intersection = words1 & words2
        union = words1 | words2

        intersection.size.to_f / union.size.to_f
      end

      def calculate_description_similarity(desc1, desc2)
        return 0.0 if desc1.nil? || desc2.nil? || desc1.empty? || desc2.empty?

        words1 = Set.new(desc1.downcase.scan(/\w+/).select { |w| w.length > 3 })
        words2 = Set.new(desc2.downcase.scan(/\w+/).select { |w| w.length > 3 })

        return 0.0 if words1.empty? || words2.empty?

        intersection = words1 & words2
        union = words1 | words2

        intersection.size.to_f / union.size.to_f
      end

      def calculate_message_type_similarity(messages1, messages2)
        return 0.0 if messages1.empty? || messages2.empty?

        subscribes1 = Set.new((messages1['subscribes_to'] || []).map(&:downcase))
        subscribes2 = Set.new((messages2['subscribes_to'] || []).map(&:downcase))
        publishes1 = Set.new((messages1['publishes'] || []).map(&:downcase))
        publishes2 = Set.new((messages2['publishes'] || []).map(&:downcase))

        all_messages1 = subscribes1 | publishes1
        all_messages2 = subscribes2 | publishes2

        return 0.0 if all_messages1.empty? || all_messages2.empty?

        intersection = all_messages1 & all_messages2
        union = all_messages1 | all_messages2

        intersection.size.to_f / union.size.to_f
      end

      def analyze_similarity_reasons(dept1, dept2)
        reasons = []

        # Check keyword overlap
        common_keywords = Set.new(dept1[:keywords]) & Set.new(dept2[:keywords])
        if common_keywords.size > 2
          reasons << "Share #{common_keywords.size} common keywords: #{common_keywords.to_a.join(', ')}"
        end

        # Check capability themes
        capability_words1 = Set.new(dept1[:capabilities].join(' ').downcase.scan(/\w+/))
        capability_words2 = Set.new(dept2[:capabilities].join(' ').downcase.scan(/\w+/))
        common_capability_words = capability_words1 & capability_words2

        if common_capability_words.size > 3
          key_words = common_capability_words.select { |word|
            %w[water waste management maintenance repair infrastructure emergency response].include?(word)
          }
          if key_words.any?
            reasons << "Both handle #{key_words.join(', ')} related functions"
          end
        end

        # Check description overlap
        desc_words1 = Set.new(dept1[:description].downcase.scan(/\w+/).select { |w| w.length > 4 })
        desc_words2 = Set.new(dept2[:description].downcase.scan(/\w+/).select { |w| w.length > 4 })
        common_desc_words = desc_words1 & desc_words2

        if common_desc_words.size > 2
          important_words = common_desc_words.select { |word|
            %w[infrastructure maintenance emergency response management systems].include?(word)
          }
          if important_words.any?
            reasons << "Similar focus areas: #{important_words.join(', ')}"
          end
        end

        reasons
      end
    end
  end
end