# doge_vsm/operations/create_consolidated_departments_tool.rb

require 'yaml'

module DogeVSM
  class Operations < VSM::Operations
    class CreateConsolidatedDepartmentsTool < VSM::ToolCapsule
      tool_name 'create_consolidated_departments'
      tool_description 'Create new consolidated department YAML files from structured consolidation recommendations'
      tool_schema({
        type: 'object',
        properties: {
          consolidations: {
            type: 'object',
            description: 'Structured consolidation recommendations where keys are new department names and values contain old_department_names array and reason',
            additionalProperties: {
              type: 'object',
              properties: {
                old_department_names: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Array of original department names to be merged'
                },
                reason: {
                  type: 'string',
                  description: 'Explanation for why these departments should be combined'
                },
                enhanced_capabilities: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Additional capabilities gained through consolidation synergies'
                }
              },
              required: ['old_department_names', 'reason']
            }
          }
        },
        required: ['consolidations']
      })

      def run(args)
        consolidations_data = args[:consolidations] || args["consolidations"]
        
        # Debug logging to understand what we received
        if ENV['VSM_DEBUG_STREAM']
          puts "CreateConsolidatedDepartmentsTool received args: #{args.inspect}"
          puts "Consolidations data: #{consolidations_data.inspect}"
        end
        
        if consolidations_data.nil? || consolidations_data.empty?
          error_msg = "No consolidation data provided. Received args keys: #{args.keys.join(', ')}"
          return { 
            error: error_msg, 
            total_consolidations: 0,
            successful_consolidations: 0,
            consolidations: [],
            errors: [error_msg]
          }
        end

        results = []
        errors = []

        consolidations_data.each do |new_dept_name, consolidation_info|
          begin
            # Extract old department names, reason, and enhanced capabilities
            old_names = consolidation_info[:old_department_names] || consolidation_info["old_department_names"] || []
            reason = consolidation_info[:reason] || consolidation_info["reason"] || "No reason provided"
            enhanced_capabilities = consolidation_info[:enhanced_capabilities] || consolidation_info["enhanced_capabilities"] || []

            if old_names.empty?
              errors << "No old department names provided for #{new_dept_name}"
              next
            end

            # Create the consolidated department with enhanced capabilities
            result = create_consolidated_department(new_dept_name, old_names, reason, enhanced_capabilities)
            results << result

          rescue => e
            errors << "Error processing #{new_dept_name}: #{e.message}"
          end
        end

        {
          total_consolidations: results.length,
          successful_consolidations: results.select { |r| r[:success] }.length,
          consolidations: results,
          errors: errors,
          summary: generate_consolidation_summary(results)
        }
      end

      private

      def create_consolidated_department(new_dept_name, old_names, reason, enhanced_capabilities = [])
        begin
          # Load existing department YAML files
          old_departments = load_old_departments(old_names)
          
          if old_departments.empty?
            return {
              success: false,
              new_department_name: new_dept_name,
              error: "No valid department YAML files found for: #{old_names.join(', ')}"
            }
          end

          # Merge the departments into a new configuration
          merged_config = merge_departments(new_dept_name, old_departments, reason, enhanced_capabilities)
          
          # Generate new YAML filename
          yaml_filename = generate_yaml_filename(new_dept_name)
          yaml_path = File.join(Dir.pwd, yaml_filename)

          # Write the new consolidated YAML file
          File.write(yaml_path, merged_config.to_yaml)

          # Rename old department YAML files to .doged suffix
          doged_files = doge_old_department_files(old_departments)

          {
            success: true,
            new_department_name: new_dept_name,
            yaml_file: yaml_filename,
            merged_departments: old_names,
            reason: reason,
            capabilities_count: merged_config['capabilities']&.length || 0,
            keywords_count: merged_config['keywords']&.length || 0,
            doged_files: doged_files
          }

        rescue => e
          {
            success: false,
            new_department_name: new_dept_name,
            error: "Failed to create consolidated department: #{e.message}"
          }
        end
      end

      def load_old_departments(old_names)
        departments = []
        
        old_names.each do |dept_name|
          yaml_files = find_yaml_files_for_department(dept_name)
          
          yaml_files.each do |yaml_file|
            begin
              config = YAML.load_file(yaml_file)
              departments << {
                name: dept_name,
                file: yaml_file,
                config: config
              }
            rescue => e
              puts "WARNING: Could not load #{yaml_file}: #{e.message}"
            end
          end
        end
        
        departments
      end

      def find_yaml_files_for_department(dept_name)
        # For snake_case department names (e.g., "utilities_department"), 
        # look for exact filename matches first
        potential_filenames = [
          "#{dept_name}.yml",                                    # Exact match (e.g., utilities_department.yml)
          "#{dept_name.downcase}.yml",                          # Lowercase version  
          "#{dept_name.downcase.gsub(/\s+/, '_')}.yml",         # Convert spaces to underscores
          "#{dept_name.downcase.gsub(/\s+/, '_')}_department.yml", # Add _department suffix
          "#{dept_name.downcase.gsub(/\s+/, '')}.yml",          # Remove spaces
          "#{dept_name.downcase.gsub(/[^a-z0-9]/, '_')}.yml"    # Replace non-alphanumeric with underscores
        ]

        found_files = []
        potential_filenames.each do |filename|
          filepath = File.join(Dir.pwd, filename)
          found_files << filepath if File.exist?(filepath)
        end

        # If no direct filename matches, search by department name field in YAML files
        if found_files.empty?
          Dir.glob("*_department.yml").each do |yml_file|
            begin
              config = YAML.load_file(yml_file)
              # Match against the 'name' field in the department section (this is the snake_case identifier)
              if config && config['department'] && config['department']['name'] == dept_name
                found_files << File.join(Dir.pwd, yml_file)
              # Also check display_name as fallback
              elsif config && config['department'] && config['department']['display_name'] && 
                   config['department']['display_name'].downcase.include?(dept_name.downcase)
                found_files << File.join(Dir.pwd, yml_file)
              end
            rescue => e
              # Skip files that can't be parsed, but log the error for debugging
              puts "Warning: Could not parse #{yml_file} while searching for #{dept_name}: #{e.message}" if ENV['VSM_DEBUG_STREAM']
            end
          end
        end

        if found_files.empty?
          puts "Warning: No YAML files found for department: #{dept_name}" if ENV['VSM_DEBUG_STREAM']
          puts "Available department files: #{Dir.glob('*_department.yml').join(', ')}" if ENV['VSM_DEBUG_STREAM']
        end

        found_files.uniq
      end

      def merge_departments(new_dept_name, old_departments, reason, enhanced_capabilities = [])
        # Generate the department name for the YAML (snake_case)
        dept_name = generate_department_name(new_dept_name)
        
        merged = {
          'department' => {
            'name' => dept_name,
            'display_name' => new_dept_name,
            'description' => generate_merged_description(old_departments, reason),
            'invariants' => [
              'serve citizens efficiently',
              'respond to emergencies promptly', 
              'maintain operational readiness'
            ]
          },
          'capabilities' => [],
          'message_types' => {
            'subscribes_to' => [],
            'publishes' => []
          },
          'routing_rules' => {},
          'message_actions' => {},
          'action_configs' => {},
          'ai_analysis' => {
            'enabled' => false,
            'context' => "You are the #{dept_name} department. Handle #{generate_merged_description(old_departments, reason).downcase}."
          },
          'logging' => {
            'level' => 'info',
            'statistics_interval' => 300
          },
          'consolidation_info' => {
            'merged_from' => old_departments.map { |d| d[:name] },
            'reason' => reason,
            'created_at' => Time.now.iso8601
          }
        }

        # Merge all capabilities 
        old_departments.each do |dept|
          config = dept[:config] || {}
          
          # Merge capabilities
          if config['capabilities']
            merged['capabilities'].concat(config['capabilities'])
          end
          
          # Merge message types
          if config['message_types']
            if config['message_types']['subscribes_to']
              merged['message_types']['subscribes_to'].concat(config['message_types']['subscribes_to'])
            end
            if config['message_types']['publishes']
              merged['message_types']['publishes'].concat(config['message_types']['publishes'])
            end
          end

          # Merge routing rules
          if config['routing_rules']
            merged['routing_rules'].merge!(config['routing_rules'])
          end

          # Merge message actions
          if config['message_actions']
            merged['message_actions'].merge!(config['message_actions'])
          end

          # Merge action configs
          if config['action_configs']
            merged['action_configs'].merge!(config['action_configs'])
          end
        end

        # Add enhanced capabilities from consolidation analysis
        if enhanced_capabilities && !enhanced_capabilities.empty?
          merged['capabilities'].concat(enhanced_capabilities)
        end

        # Remove duplicates and sort
        merged['capabilities'] = merged['capabilities'].uniq.sort
        merged['message_types']['subscribes_to'] = merged['message_types']['subscribes_to'].uniq.sort
        merged['message_types']['publishes'] = merged['message_types']['publishes'].uniq.sort

        merged
      end

      def generate_department_name(display_name)
        # Convert display name to snake_case for the department name
        display_name.downcase
                    .gsub(/[^a-z0-9\s&]/, '') # Remove special characters except & and spaces
                    .gsub(/\s*&\s*/, '_and_') # Convert "word & word" to "word_and_word"
                    .gsub(/\s+/, '_') # Convert spaces to underscores
                    .gsub(/_+/, '_') # Collapse multiple underscores
                    .gsub(/^_|_$/, '') # Remove leading/trailing underscores
      end

      def generate_merged_description(old_departments, reason)
        dept_names = old_departments.map { |d| d[:name] }.join(', ')
        "Consolidated department combining #{dept_names}. #{reason}"
      end

      def doge_old_department_files(old_departments)
        doged_files = []
        
        old_departments.each do |dept|
          original_file = dept[:file]
          next unless original_file && File.exist?(original_file)
          
          # Create new filename with .doged suffix
          doged_filename = "#{original_file}.doged"
          
          begin
            File.rename(original_file, doged_filename)
            doged_files << {
              original: File.basename(original_file),
              doged: File.basename(doged_filename),
              department_name: dept[:name]
            }
          rescue => e
            puts "WARNING: Could not rename #{original_file} to .doged: #{e.message}"
          end
        end
        
        doged_files
      end

      def generate_yaml_filename(dept_name)
        base_name = dept_name.downcase.gsub(/[^a-z0-9]/, '_').gsub(/_+/, '_')
        # Remove trailing underscore if present
        base_name = base_name.sub(/_$/, '')
        
        # Ensure we don't create double "_department" suffixes
        # Remove existing "_department" suffix if present before adding it back
        base_name = base_name.sub(/_department$/, '')
        
        "#{base_name}_department.yml"
      end

      def generate_consolidation_summary(results)
        successful = results.select { |r| r[:success] }
        failed = results.reject { |r| r[:success] }

        {
          total_departments_created: successful.length,
          total_departments_merged: successful.sum { |r| r[:merged_departments]&.length || 0 },
          total_capabilities: successful.sum { |r| r[:capabilities_count] || 0 },
          total_keywords: successful.sum { |r| r[:keywords_count] || 0 },
          failed_consolidations: failed.length,
          new_department_files: successful.map { |r| r[:yaml_file] }
        }
      end
    end
  end
end