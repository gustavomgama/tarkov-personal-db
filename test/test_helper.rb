require "simplecov"
SimpleCov.merge_timeout 3600
SimpleCov.start do
  skip "/test/"
  skip "lib/tasks"
  skip "config/initializers/bootsnap.rb"
  minimum_coverage 99.8
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

module ActiveSupport
  class TestCase
    include TarkovTestFixtures

    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
