# frozen_string_literal: true

module FactDb
  class Error < StandardError; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
  class ResolutionError < Error; end
  class ExtractionError < Error; end
  class ConfigurationError < Error; end
end
