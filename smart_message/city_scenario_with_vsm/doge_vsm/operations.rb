# doge_vsm/operations.rb

require_relative 'operations/load_departments_tool'
require_relative 'operations/recommendation_generator_tool'
require_relative 'operations/create_consolidated_departments_tool'
require_relative 'operations/template_validation_tool'
require_relative 'operations/department_template_generator_tool'

module DogeVSM
  class Operations < VSM::Operations
    # Tool classes are loaded from separate files
    # - LoadDepartmentsTool: operations/load_departments_tool.rb
    # - RecommendationGeneratorTool: operations/recommendation_generator_tool.rb
    # - CreateConsolidatedDepartmentsTool: operations/create_consolidated_departments_tool.rb
    # - TemplateValidationTool: operations/template_validation_tool.rb
    # - DepartmentTemplateGeneratorTool: operations/department_template_generator_tool.rb
  end
end