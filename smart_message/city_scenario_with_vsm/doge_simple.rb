#!/usr/bin/env ruby
# doge_simple.rb - Simplified DOGE using core VSM concepts without full Intelligence system

require_relative 'vsm/lib/vsm'
require 'yaml'
require 'set'

# Simplified DOGE that works directly with Operations tools
class SimpleDOGE
  def initialize
    @tools = {
      'load_departments' => LoadDepartmentsTool.new,
      'calculate_similarity' => SimilarityCalculatorTool.new,
      'generate_recommendations' => RecommendationGeneratorTool.new
    }
  end

  def analyze_departments
    puts "🇺🇸 Department of Government Efficiency - Analysis System"
    puts "=" * 60

    # Step 1: Load departments
    puts "📊 Loading department configurations..."
    departments_result = @tools['load_departments'].run({ pattern: '*.yml' })
    puts "   Loaded #{departments_result[:count]} departments"

    return if departments_result[:count] == 0

    # Step 2: Calculate similarity
    puts "\n🔎 Calculating department similarities..."
    similarity_result = @tools['calculate_similarity'].run({
      departments: departments_result[:departments],
      threshold: 0.15
    })
    puts "   Found #{similarity_result[:combinations_found]} consolidation opportunities"

    return if similarity_result[:combinations_found] == 0

    # Step 3: Generate recommendations
    puts "\n📋 Generating detailed recommendations..."
    recommendations = @tools['generate_recommendations'].run({
      combinations: similarity_result[:combinations]
    })

    # Display results
    display_results(recommendations)
  end

  private

  def display_results(recommendations)
    puts "\n📋 ANALYSIS COMPLETE"
    puts "=" * 60
    puts "Total Recommendations: #{recommendations[:total_recommendations]}"
    puts "Estimated Annual Savings: $#{format_currency(recommendations[:summary][:total_estimated_annual_savings])}"
    
    puts "\n🏛️ Top Consolidation Themes:"
    recommendations[:summary][:top_consolidation_themes].each do |theme, count|
      puts "  • #{theme}: #{count} opportunities"
    end

    puts "\n📄 Detailed Recommendations:"
    recommendations[:recommendations].first(5).each_with_index do |rec, i|
      puts "\n#{i+1}. #{rec[:proposed_name]} (#{rec[:similarity_score]}% similarity)"
      puts "   Consolidating: #{rec[:departments].map { |d| d[:name] }.join(' + ')}"
      puts "   Benefits: #{rec[:benefits].first(2).join(', ')}"
      puts "   Est. Savings: $#{format_currency(rec[:implementation][:estimated_savings][:estimated_annual_savings])}/year"
    end

    puts "\n✅ DOGE Analysis Complete"
  end

  def format_currency(amount)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  # Tool implementations (same as VSM version but as regular classes)
  class LoadDepartmentsTool
    def run(args)
      pattern = args[:pattern] || '*.yml'
      departments = []
      
      Dir.glob(pattern).each do |file|
        begin
          config = YAML.load_file(file)
          next unless config && config['department']
          
          department = {
            file: file,
            name: config['department']['name'],
            display_name: config['department']['display_name'],
            description: config['department']['description'],
            capabilities: config['capabilities'] || [],
            message_types: config['message_types'] || {},
            keywords: extract_keywords(config)
          }
          
          departments << department
        rescue => e
          # Log error but continue processing
        end
      end
      
      {
        count: departments.length,
        departments: departments
      }
    end

    private

    def extract_keywords(config)
      keywords = Set.new
      
      # Extract from description
      if config['department'] && config['department']['description']
        description_words = config['department']['description']
          .downcase
          .scan(/\w+/)
          .select { |word| word.length > 3 }
        keywords.merge(description_words)
      end
      
      # Extract from routing rule keywords
      if config['routing_rules']
        config['routing_rules'].each do |_, rules|
          Array(rules).each do |rule|
            if rule['keywords']
              keywords.merge(rule['keywords'].map(&:downcase))
            end
          end
        end
      end
      
      # Extract from capabilities
      if config['capabilities']
        config['capabilities'].each do |capability|
          capability_words = capability
            .downcase
            .scan(/\w+/)
            .select { |word| word.length > 3 }
          keywords.merge(capability_words)
        end
      end
      
      keywords.to_a
    end
  end

  class SimilarityCalculatorTool
    def run(args)
      departments = args[:departments]
      threshold = args[:threshold] || 0.15
      combinations = []

      departments.each_with_index do |dept1, i|
        departments.each_with_index do |dept2, j|
          next if i >= j

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

      {
        threshold: threshold,
        combinations_found: combinations.length,
        combinations: combinations.sort_by { |combo| -combo[:score] }
      }
    end

    private

    def calculate_department_similarity(dept1, dept2)
      scores = []

      # Keyword overlap (40% weight)
      keyword_similarity = calculate_keyword_similarity(dept1[:keywords], dept2[:keywords])
      scores << keyword_similarity * 0.4

      # Capability overlap (30% weight)  
      capability_similarity = calculate_capability_similarity(dept1[:capabilities], dept2[:capabilities])
      scores << capability_similarity * 0.3

      # Description similarity (20% weight)
      description_similarity = calculate_description_similarity(dept1[:description], dept2[:description])
      scores << description_similarity * 0.2

      # Message type overlap (10% weight)
      message_similarity = calculate_message_type_similarity(dept1[:message_types], dept2[:message_types])
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
        reasons << "Share #{common_keywords.size} common keywords: #{common_keywords.to_a.first(5).join(', ')}"
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

  class RecommendationGeneratorTool
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

# Run the analysis
if __FILE__ == $0
  doge = SimpleDOGE.new
  doge.analyze_departments
end