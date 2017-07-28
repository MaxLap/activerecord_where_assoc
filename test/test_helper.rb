# frozen_string_literal: true

require_relative "support/load_test_env"
require "minitest/autorun"


module TestHelpers
  def self.condition_value_result_for(target_association, *models)
    models.map { |model| model.test_condition_value_for(target_association) }.inject(:*)
  end
  delegate :condition_value_result_for, to: "TestHelpers"
end


class MyMinitestSpec < Minitest::Spec
  include TestHelpers

  # Annoying stuff for tests to run in transactions
  include ActiveRecord::TestFixtures
  self.use_transactional_tests = true
  def run_in_transaction?
    self.use_transactional_tests
  end
end

# Use my custom test case for the specs
MiniTest::Spec.register_spec_type(//, MyMinitestSpec)
