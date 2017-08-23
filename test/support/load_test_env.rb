# frozen_string_literal: true

require "bundler/setup"
require "pry"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_record_where_assoc"
require "active_support"

require_relative "database_setup"
require_relative "schema"
require_relative "models"


module TestHelpers
  def self.condition_value_result_for(*source_associations)
    source_associations.map do |source_association|
      model_name, association = source_association.to_s.split("_", 2)
      value = BaseTestModel.model_associations_conditions[[model_name, association]]

      raise "No condition #{source_association} found" if value.nil?

      value
    end.inject(:*)
  end
  delegate :condition_value_result_for, to: "TestHelpers"
end
