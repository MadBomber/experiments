# doge_vsm/operations/load_departments_tool.rb

module DogeVSM
  class Operations < VSM::Operations
    class LoadDepartmentsTool < VSM::ToolCapsule
      tool_name 'load_departments'
      tool_description 'Load and parse all department YAML configuration files'
      tool_schema({
        type: 'object',
        properties: {
          pattern: { type: 'string', description: 'Glob pattern for YAML files (default: *.yml)' }
        }
      })

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
  end
end