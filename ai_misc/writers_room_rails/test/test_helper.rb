ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Pundit policies are tested by calling .new(user, record) directly — no helper module needed
    # (pundit 2.5.x ships only pundit/rspec.rb; there is no minitest helper module)

    # Add more helper methods to be used by all tests here...
  end
end
