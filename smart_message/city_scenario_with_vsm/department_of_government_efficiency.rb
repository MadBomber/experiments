#!/usr/bin/env ruby
# department_of_government_efficiency.rb

require 'yaml'
require 'set'

class DOGE
  def initialize
    @departments = []
    @similarity_threshold = 0.15  # Minimum similarity score to suggest combination
  end

  def analyze_all_departments
    load_all_department_configs
    find_similar_departments
  end

  private

  def load_all_department_configs
    puts "🔍 Loading department configurations..."

    Dir.glob("*.yml").each do |file|
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

        @departments << department
        puts "   ✅ Loaded #{department[:name]} (#{department[:capabilities].length} capabilities)"
      rescue => e
        puts "   ❌ Error loading #{file}: #{e.message}"
      end
    end

    puts "\n📊 Total departments loaded: #{@departments.length}\n"
  end

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

  def find_similar_departments
    puts "🔎 Analyzing department similarities...\n"

    combinations_found = []

    @departments.each_with_index do |dept1, i|
      @departments.each_with_index do |dept2, j|
        next if i >= j  # Avoid duplicate comparisons

        similarity_score = calculate_similarity(dept1, dept2)

        if similarity_score >= @similarity_threshold
          combinations_found << {
            dept1: dept1,
            dept2: dept2,
            score: similarity_score,
            reasons: analyze_similarity_reasons(dept1, dept2)
          }
        end
      end
    end

    if combinations_found.empty?
      puts "✅ No similar departments found that meet the similarity threshold (#{@similarity_threshold})"
    else
      puts "🎯 Found #{combinations_found.length} potential department combinations:\n"

      combinations_found.sort_by { |combo| -combo[:score] }.each do |combo|
        recommend_combination(combo)
        puts "\n" + "="*80 + "\n"
      end
    end
  end

  def calculate_similarity(dept1, dept2)
    scores = []

    # Keyword overlap
    keyword_similarity = calculate_keyword_similarity(dept1[:keywords], dept2[:keywords])
    scores << keyword_similarity * 0.4

    # Capability overlap
    capability_similarity = calculate_capability_similarity(dept1[:capabilities], dept2[:capabilities])
    scores << capability_similarity * 0.3

    # Description similarity
    description_similarity = calculate_description_similarity(dept1[:description], dept2[:description])
    scores << description_similarity * 0.2

    # Message type overlap
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

    # Convert capabilities to word sets for comparison
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

  def recommend_combination(combo)
    dept1 = combo[:dept1]
    dept2 = combo[:dept2]
    score = combo[:score]
    reasons = combo[:reasons]

    puts "🔗 RECOMMENDATION: Combine departments (Similarity: #{(score * 100).round(1)}%)"
    puts "   📁 #{dept1[:display_name]} (#{dept1[:name]})"
    puts "   📁 #{dept2[:display_name]} (#{dept2[:name]})"
    puts ""

    puts "📋 Why these should be combined:"
    reasons.each { |reason| puts "   • #{reason}" }

    puts "\n🎯 Proposed combined department:"

    # Generate combined name
    combined_name = generate_combined_name(dept1, dept2)
    puts "   📛 Name: #{combined_name}"

    # Combine capabilities
    all_capabilities = (dept1[:capabilities] + dept2[:capabilities]).uniq
    puts "   ⚡ Total Capabilities: #{all_capabilities.length}"

    puts "   📝 Combined Capabilities:"
    all_capabilities.each { |cap| puts "      - #{cap}" }

    # Show which files would be affected
    puts "\n📄 Configuration files to merge:"
    puts "   🗂️  #{dept1[:file]} + #{dept2[:file]} → #{combined_name.downcase.gsub(' ', '_')}.yml"

    # Estimate resource savings
    puts "\n💰 Benefits:"
    puts "   • Reduce #{dept1[:capabilities].length + dept2[:capabilities].length - all_capabilities.length} duplicate capabilities"
    puts "   • Consolidate similar infrastructure management under one department"
    puts "   • Improve coordination between related services"
    puts "   • Reduce operational overhead"
  end

  def generate_combined_name(dept1, dept2)
    # Extract key terms from both department names
    name1_words = dept1[:display_name].downcase.split
    name2_words = dept2[:display_name].downcase.split

    # Look for common infrastructure themes
    if (name1_words + name2_words).any? { |word| word.match?(/water|waste|sewer|utility/) }
      return "Water & Utilities Management"
    elsif (name1_words + name2_words).any? { |word| word.match?(/transport|traffic|transit/) }
      return "Transportation & Transit Management"
    elsif (name1_words + name2_words).any? { |word| word.match?(/environment|health|safety/) }
      return "Environmental Health & Safety"
    elsif (name1_words + name2_words).any? { |word| word.match?(/public|works|infrastructure/) }
      return "Public Works & Infrastructure"
    else
      # Fallback: combine the unique words
      all_words = (name1_words + name2_words).uniq
      key_words = all_words.reject { |word| %w[and department management].include?(word) }
      "#{key_words.map(&:capitalize).join(' ')} Department"
    end
  end
end

# Run the analysis
if __FILE__ == $0
  big_balls = DOGE.new
  big_balls.analyze_all_departments
end
