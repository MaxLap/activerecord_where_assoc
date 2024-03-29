# frozen_string_literal: true

require "bundler/setup"
require "pry"

require_relative "../../lib/active_record_where_assoc"

if ENV["DB"] == "mysql" && [ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR].join('.') < '5.1'
  puts "Exiting from tests with MySQL as success without doing them."
  puts "This is because automated test won't seem to run MySQL for some reason for this old Rails version."
  exit 0
end

require "active_support"

require_relative "database_setup"
require_relative "schema"
require_relative "models"

require "niceql" if RUBY_VERSION >= "2.3.0"


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
