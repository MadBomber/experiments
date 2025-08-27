# doge_vsm/operations/load_departments_tool.rb

module DogeVSM
  class Operations < VSM::Operations
    class LoadDepartmentsTool < VSM::ToolCapsule
      tool_name 'load_departments'
      tool_description 'Load and parse all department YAML configuration files with validation against template structure'
      tool_schema({
        type: 'object',
        properties: {
          pattern: { type: 'string', description: 'Glob pattern for YAML files (default: *_department.yml)' },
          validate: { type: 'boolean', description: 'Validate against template structure (default: true)' },
          template_path: { type: 'string', description: 'Path to template file (default: generic_department_sample.yml)' }
        }
      })

      def run(args)
        pattern = args[:pattern] || '*_department.yml'
        validate = args[:validate] != false  # Default to true
        template_path = args[:template_path] || 'generic_department_sample.yml'
        
        departments = []
        validation_results = []
        errors = []

        Dir.glob(pattern).each do |file|
          # Skip template file itself
          next if file == template_path || file.include?('generic_department_sample')
          
          begin
            config = YAML.load_file(file)
            next unless config && config['department']

            # Enhanced department data extraction using template structure
            department = {
              file: file,
              name: config['department']['name'],
              display_name: config['department']['display_name'],
              description: config['department']['description'],
              invariants: config['department']['invariants'] || [],
              capabilities: config['capabilities'] || [],
              message_types: config['message_types'] || {},
              routing_rules: config['routing_rules'] || {},
              message_actions: config['message_actions'] || {},
              action_configs: config['action_configs'] || {},
              ai_analysis: config['ai_analysis'] || { enabled: false },
              logging: config['logging'] || { level: 'info', statistics_interval: 300 },
              keywords: extract_keywords(config),
              resources: config['resources'] || {},
              integrations: config['integrations'] || {},
              custom_settings: config['custom_settings'] || {}
            }

            # Validate against template if requested
            if validate && File.exist?(template_path)
              validation = validate_against_template(config, template_path, file)
              validation_results << validation
              department[:validation] = validation
            end

            departments << department
          rescue => e
            error_msg = "Failed to parse #{file}: #{e.message}"
            errors << error_msg
            # Log error but continue processing
            puts "Warning: #{error_msg}" if ENV['VSM_DEBUG_STREAM']
          end
        end

        result = {
          count: departments.length,
          departments: departments,
          errors: errors
        }

        # Add validation summary if validation was performed
        if validate && validation_results.any?
          result[:validation_summary] = {
            total_validated: validation_results.length,
            valid_count: validation_results.count { |v| v[:valid] },
            invalid_count: validation_results.count { |v| !v[:valid] },
            average_completeness: validation_results.map { |v| v[:completeness_score] || 0 }.sum.to_f / validation_results.length
          }
        end

        result
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

        # Extract from invariants (template structure)
        if config['department'] && config['department']['invariants']
          config['department']['invariants'].each do |invariant|
            invariant_words = invariant
              .downcase
              .scan(/\w+/)
              .select { |word| word.length > 3 }
            keywords.merge(invariant_words)
          end
        end

        # Extract from action configs response templates
        if config['action_configs']
          config['action_configs'].each do |_, action_config|
            if action_config['response_template']
              template_words = action_config['response_template']
                .downcase
                .gsub(/\{\{.*?\}\}/, '') # Remove template variables
                .scan(/\w+/)
                .select { |word| word.length > 3 }
              keywords.merge(template_words)
            end
          end
        end

        keywords.to_a
      end

      def validate_against_template(config, template_path, file_path)
        begin
          template = YAML.load_file(template_path)
          
          # Define required structure based on template
          required_sections = %w[department capabilities message_types routing_rules message_actions action_configs logging]
          department_required = %w[name display_name description invariants]
          
          errors = []
          warnings = []
          
          # Check required sections
          required_sections.each do |section|
            unless config.key?(section)
              errors << "Missing required section: #{section}"
            end
          end

          # Check department fields
          if config['department']
            department_required.each do |field|
              unless config['department'].key?(field)
                errors << "Missing required department field: #{field}"
              end
            end
          else
            errors << "Missing required 'department' section"
          end

          # Calculate completeness score
          total_sections = required_sections.length + %w[ai_analysis resources integrations custom_settings].length
          present_sections = (required_sections + %w[ai_analysis resources integrations custom_settings]).count { |section| config.key?(section) }
          completeness_score = (present_sections.to_f / total_sections * 100).round(1)

          {
            valid: errors.empty?,
            file: file_path,
            errors: errors,
            warnings: warnings,
            completeness_score: completeness_score
          }
        rescue => e
          {
            valid: false,
            file: file_path,
            errors: ["Validation failed: #{e.message}"],
            warnings: [],
            completeness_score: 0
          }
        end
      end
    end
  end
end