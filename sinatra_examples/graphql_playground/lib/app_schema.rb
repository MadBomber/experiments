# lib/app_schema.rb

require 'graphql'
require_relative 'query_type'

class AppSchema < GraphQL::Schema
  query QueryType
end
