# doge_vsm/operations.rb

require_relative 'operations/load_departments_tool'
require_relative 'operations/similarity_calculator_tool'
require_relative 'operations/recommendation_generator_tool'

module DogeVSM
  class Operations < VSM::Operations
    # Tool classes are loaded from separate files
    # - LoadDepartmentsTool: operations/load_departments_tool.rb
    # - SimilarityCalculatorTool: operations/similarity_calculator_tool.rb
    # - RecommendationGeneratorTool: operations/recommendation_generator_tool.rb
  end
end