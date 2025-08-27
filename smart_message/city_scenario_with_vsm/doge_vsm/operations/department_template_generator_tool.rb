# doge_vsm/operations/department_template_generator_tool.rb

module DogeVSM
  class Operations < VSM::Operations
    class DepartmentTemplateGeneratorTool < VSM::ToolCapsule
      tool_name 'generate_department_template'
      tool_description 'Generate a new department YAML file from the generic template with customized values'
      tool_schema({
        type: 'object',
        properties: {
          department_name: { type: 'string', description: 'Name of the new department (e.g., animal_control)' },
          display_name: { type: 'string', description: 'Human-readable display name (e.g., Animal Control)' },
          description: { type: 'string', description: 'Brief description of department responsibilities' },
          capabilities: { 
            type: 'array', 
            items: { type: 'string' },
            description: 'List of department capabilities'
          },
          keywords: {
            type: 'array',
            items: { type: 'string' },
            description: 'Keywords for emergency routing (e.g., animal, control, bite, stray)'
          },
          template_path: { type: 'string', description: 'Path to template file (default: generic_department_sample.yml)' },
          output_path: { type: 'string', description: 'Output file path (default: {department_name}.yml)' },
          ai_enabled: { type: 'boolean', description: 'Enable AI analysis for this department (default: true)' }
        },
        required: ['department_name', 'display_name', 'description']
      })

      def run(args)
        department_name = args[:department_name]
        display_name = args[:display_name]
        description = args[:description]
        capabilities = args[:capabilities] || generate_default_capabilities(description)
        keywords = args[:keywords] || extract_keywords_from_text(description + ' ' + capabilities.join(' '))
        template_path = args[:template_path] || 'generic_department_sample.yml'
        output_path = args[:output_path] || "#{department_name}.yml"
        ai_enabled = args[:ai_enabled] != false

        unless File.exist?(template_path)
          return {
            success: false,
            error: "Template file not found: #{template_path}"
          }
        end

        begin
          # Load and customize template
          template_content = File.read(template_path)
          customized_content = customize_template(
            template_content,
            department_name: department_name,
            display_name: display_name,
            description: description,
            capabilities: capabilities,
            keywords: keywords,
            ai_enabled: ai_enabled
          )

          # Write the new department file
          File.write(output_path, customized_content)

          # Validate the generated file
          validation_result = validate_generated_file(output_path, template_path)

          {
            success: true,
            output_file: output_path,
            department_name: department_name,
            display_name: display_name,
            validation: validation_result,
            generated_capabilities: capabilities,
            generated_keywords: keywords
          }

        rescue => e
          {
            success: false,
            error: "Failed to generate department template: #{e.message}"
          }
        end
      end

      private

      def customize_template(template_content, options)
        content = template_content.dup

        # Replace department metadata
        content.gsub!('example_department', options[:department_name])
        content.gsub!('Example Department', options[:display_name])
        content.gsub!('Handles sample operations and demonstrates the department configuration structure for new city services.', options[:description])

        # Replace capabilities section
        capabilities_yaml = options[:capabilities].map { |cap| "- #{cap}" }.join("\n")
        content.gsub!(
          /capabilities:\n- Handle routine service requests and citizen inquiries.*?- Provide status updates and health monitoring information/m,
          "capabilities:\n#{capabilities_yaml}"
        )

        # Replace keywords in routing rules
        keywords_yaml = options[:keywords].map { |kw| "    - #{kw}" }.join("\n")
        content.gsub!(
          /    keywords:.*?    - request/m,
          "    keywords:\n#{keywords_yaml}"
        )

        # Update AI analysis context
        ai_context = generate_ai_context(options[:department_name], options[:description])
        content.gsub!(
          /context: >.*?escalate to the appropriate department immediately\./m,
          "context: >\n    #{ai_context}"
        )

        # Set AI enabled status
        content.gsub!('enabled: true', "enabled: #{options[:ai_enabled]}")

        # Update message types with department-specific examples
        message_examples = generate_message_examples(options[:department_name])
        content.gsub!(
          /publishes:\n  - example_service_complete.*?  # Add department-specific message types this service will broadcast/m,
          "publishes:\n#{message_examples[:publishes]}\n  # Add department-specific message types this service will broadcast"
        )

        # Update action configs with department-specific examples
        action_configs = generate_action_configs(options[:department_name], options[:display_name])
        content.gsub!(
          /handle_example_service_complete:.*?    publish_response: true/m,
          action_configs
        )

        content
      end

      def generate_default_capabilities(description)
        # Extract capability hints from description
        base_capabilities = [
          "Handle #{description.downcase.split.first(3).join(' ')} related service requests",
          "Coordinate with other departments for complex issues",
          "Maintain department records and operational logs",
          "Respond to emergency situations within department expertise",
          "Provide status updates and health monitoring information"
        ]

        # Add specific capabilities based on common department patterns
        if description.downcase.include?('inspect')
          base_capabilities << "Conduct safety inspections and assessments"
        end
        
        if description.downcase.include?('maintain') || description.downcase.include?('repair')
          base_capabilities << "Perform maintenance and repair operations"
        end

        if description.downcase.include?('emergency') || description.downcase.include?('respond')
          base_capabilities << "Provide emergency response services"
        end

        base_capabilities
      end

      def extract_keywords_from_text(text)
        # Extract meaningful keywords from text
        words = text.downcase
          .gsub(/[^\w\s]/, ' ')
          .split
          .select { |word| word.length > 3 }
          .uniq

        # Filter out common words
        stop_words = %w[this that with from they have been some more will there their what about when time]
        words - stop_words
      end

      def generate_ai_context(department_name, description)
        "You are the #{department_name.gsub('_', ' ')} department. Your role is to #{description.downcase} 
    Always prioritize citizen safety and efficient service delivery. When processing 
    emergency calls, assess the situation quickly and determine if your department 
    has the appropriate resources and expertise to respond effectively. If not, 
    escalate to the appropriate department immediately."
      end

      def generate_message_examples(department_name)
        prefix = department_name.split('_').first(2).join('_')
        {
          publishes: [
            "  - #{prefix}_service_complete",
            "  - #{prefix}_status_update", 
            "  - #{prefix}_escalation_request"
          ].join("\n")
        }
      end

      def generate_action_configs(department_name, display_name)
        prefix = department_name.split('_').first(2).join('_')
        upper_name = department_name.upcase

        <<~YAML
        handle_#{prefix}_service_complete:
            response_template: "✅ #{upper_name}: Service request completed successfully"
            additional_actions:
            - update_service_records
            - notify_citizen
            publish_response: true
          
          handle_#{prefix}_status_update:
            response_template: "📊 #{upper_name}: Status update received and processed"
            additional_actions:
            - log_status_change
            publish_response: false
          
          handle_#{prefix}_escalation_request:
            response_template: "⚠️ #{upper_name}: Escalating to {{target_department}}"
            additional_actions:
            - identify_appropriate_department
            - transfer_case_information
            - notify_supervisor
            publish_response: true
        YAML
      end

      def validate_generated_file(file_path, template_path)
        # Use existing validation logic
        config = YAML.load_file(file_path)
        
        required_sections = %w[department capabilities message_types routing_rules message_actions action_configs logging]
        errors = []
        
        required_sections.each do |section|
          unless config.key?(section)
            errors << "Missing required section: #{section}"
          end
        end

        {
          valid: errors.empty?,
          errors: errors,
          file: file_path
        }
      end
    end
  end
end