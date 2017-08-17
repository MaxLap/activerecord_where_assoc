# frozen_string_literal: true

coverage_config = proc do
  add_filter "/test/"
end

if ENV["TRAVIS"]
  require "coveralls"
  require "simplecov"
  SimpleCov.command_name "rake test-#{ENV['DB']}"
  Coveralls.wear_merged!(&coverage_config)
elsif ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start(&coverage_config)
  SimpleCov.command_name "rake test-#{ENV['DB']}" if ENV["COVERAGE"] == "multi"
end


require_relative "support/load_test_env"
require "minitest/autorun"
require_relative "support/custom_asserts"


class MyMinitestSpec < Minitest::Spec
  include TestHelpers

  # Annoying stuff for tests to run in transactions
  include ActiveRecord::TestFixtures
  if ActiveRecord.gem_version >= Gem::Version.new("5.0")
    self.use_transactional_tests = true
    def run_in_transaction?
      self.use_transactional_tests
    end
  else
    self.use_transactional_fixtures = true
    def run_in_transaction?
      self.use_transactional_fixtures
    end
  end
end

# Use my custom test case for the specs
MiniTest::Spec.register_spec_type(//, MyMinitestSpec)
