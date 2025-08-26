# doge_vsm/operations/recommendation_generator_tool.rb

module DogeVSM
  class Operations < VSM::Operations
    class RecommendationGeneratorTool < VSM::ToolCapsule
      tool_name 'generate_recommendations'
      tool_description 'Generate detailed consolidation recommendations from similarity analysis'
      tool_schema({
        type: 'object',
        properties: {
          combinations: { type: 'array', description: 'Array of department combination objects' }
        },
        required: ['combinations']
      })

      def run(args)
        combinations = args[:combinations]
        recommendations = []

        combinations.each do |combo|
          recommendation = build_recommendation(combo)
          recommendations << recommendation
        end

        {
          total_recommendations: recommendations.length,
          recommendations: recommendations,
          summary: generate_summary(recommendations)
        }
      end

      private

      def build_recommendation(combo)
        dept1 = combo[:dept1]
        dept2 = combo[:dept2]
        score = combo[:score]
        reasons = combo[:reasons]

        combined_name = generate_combined_name(dept1, dept2)
        all_capabilities = (dept1[:capabilities] + dept2[:capabilities]).uniq
        duplicates_eliminated = dept1[:capabilities].length + dept2[:capabilities].length - all_capabilities.length

        {
          similarity_score: (score * 100).round(1),
          departments: [
            { name: dept1[:display_name], file: dept1[:file] },
            { name: dept2[:display_name], file: dept2[:file] }
          ],
          proposed_name: combined_name,
          rationale: reasons,
          capabilities: {
            total: all_capabilities.length,
            duplicates_eliminated: duplicates_eliminated,
            combined_list: all_capabilities
          },
          benefits: [
            "Eliminate #{duplicates_eliminated} duplicate capabilities",
            'Consolidate similar infrastructure management',
            'Improve coordination between related services',
            'Reduce operational overhead',
            'Streamline citizen service delivery'
          ],
          implementation: {
            files_to_merge: [dept1[:file], dept2[:file]],
            new_config_file: "#{combined_name.downcase.gsub(' ', '_')}.yml",
            estimated_savings: calculate_estimated_savings(dept1, dept2)
          }
        }
      end

      def generate_combined_name(dept1, dept2)
        name1_words = dept1[:display_name].downcase.split
        name2_words = dept2[:display_name].downcase.split

        # Look for common infrastructure themes
        if (name1_words + name2_words).any? { |word| word.match?(/water|waste|sewer|utility/) }
          'Water & Utilities Management'
        elsif (name1_words + name2_words).any? { |word| word.match?(/transport|traffic|transit/) }
          'Transportation & Transit Management'
        elsif (name1_words + name2_words).any? { |word| word.match?(/environment|health|safety/) }
          'Environmental Health & Safety'
        elsif (name1_words + name2_words).any? { |word| word.match?(/public|works|infrastructure/) }
          'Public Works & Infrastructure'
        else
          # Fallback: combine unique words
          all_words = (name1_words + name2_words).uniq
          key_words = all_words.reject { |word| %w[and department management].include?(word) }
          "#{key_words.map(&:capitalize).join(' ')} Department"
        end
      end

      def calculate_estimated_savings(dept1, dept2)
        # Simple heuristic based on capability overlap
        base_cost = 100_000  # Assumed annual cost per department
        overlap_ratio = (dept1[:capabilities] & dept2[:capabilities]).length.to_f /
                       [dept1[:capabilities].length, dept2[:capabilities].length].max

        savings = (base_cost * overlap_ratio * 0.6).round

        {
          estimated_annual_savings: savings,
          methodology: 'Based on capability overlap and assumed operational costs'
        }
      end

      def generate_summary(recommendations)
        total_departments = recommendations.map { |r| r[:departments] }.flatten.uniq { |d| d[:name] }.length
        total_capabilities_eliminated = recommendations.sum { |r| r[:capabilities][:duplicates_eliminated] }
        total_estimated_savings = recommendations.sum { |r| r[:implementation][:estimated_savings][:estimated_annual_savings] }

        {
          departments_analyzed: total_departments,
          total_consolidation_opportunities: recommendations.length,
          total_duplicate_capabilities_eliminated: total_capabilities_eliminated,
          total_estimated_annual_savings: total_estimated_savings,
          top_consolidation_themes: identify_consolidation_themes(recommendations)
        }
      end

      def identify_consolidation_themes(recommendations)
        themes = Hash.new(0)

        recommendations.each do |rec|
          case rec[:proposed_name]
          when /Water|Utilities/
            themes['Water & Utilities Management'] += 1
          when /Transportation|Transit/
            themes['Transportation Management'] += 1
          when /Environmental|Health|Safety/
            themes['Environmental Health & Safety'] += 1
          when /Public Works|Infrastructure/
            themes['Infrastructure Management'] += 1
          else
            themes['Other Consolidations'] += 1
          end
        end

        themes.sort_by { |_, count| -count }.to_h
      end
    end
  end
end