# frozen_string_literal: true

require "prime"


class BaseTestRecord < ActiveRecord::Base
  self.abstract_class = true

  # We give a distinct prime number to ever conditions we use as part of associations
  # and default_scopes, and we record it, do that we can easily get a number that would match
  # each of them by multiplying them.
  # The conditions themselves use modulo, so at long as the value is a multiple, it all works.
  @@condition_values_enumerator = Prime.each # rubocop:disable Style/ClassVars


  # Hash of [Model.name, association_name] => value
  # association_name can also be :default_scope, :custom_scope
  @@model_associations_conditions = {} # rubocop:disable Style/ClassVars

  def self.inherited(other)
    super
    value = other.test_condition_value_for(:default_scope)
    other.send(:default_scope, -> { where(testable_condition(value)) })
  end

  def self.test_condition_column
    "#{table_name}_column"
  end
  delegate :test_condition_column, to: "self.class"

  def self.test_condition_value_for(association_name)
    @@model_associations_conditions[[self.name, association_name.to_s]] ||= @@condition_values_enumerator.next
  end

  def self.test_condition_value_for?(association_name)
    @@model_associations_conditions.include?([self.name, association_name.to_s])
  end

  def self.model_associations_conditions
    @@model_associations_conditions
  end

  def self.testable_condition(value)
    "#{table_name}.#{test_condition_column} % #{value} = 0"
  end

  # Creates a relations with a conditions on the one column named after the association
  # Provides a quick_create! method to simplify model creation that match the condition in tests
  def self.testable_has_many(association_name, options = {})
    condition_value = test_condition_value_for(association_name)
    has_many(association_name, -> { where(testable_condition(condition_value)) }, options)
  end

  # does a #create! and automatically fills the column with a value that matches the merge of the condition on
  # the matching association of each passed source_associations
  def self.quick_create!(*source_associations)
    options = source_associations.extract_options!
    if !options[:allow_no_source] && source_associations.empty?
      raise "Need at least one source model or a nil instead"
    end
    source_associations = source_associations.compact

    if !options[:skip_default] && test_condition_value_for?(:default_scope)
      condition_values = test_condition_value_for(:default_scope)
    end

    if source_associations.present?
      condition_values ||= 1
      condition_values *= TestHelpers.condition_value_result_for(*source_associations)
    end

    create!(test_condition_column => condition_values)
  end

  # Receives the parameters to to #quick_create!, and creates a record for every
  # combinations missing one of the source models and the default scope
  def self.quick_creates_bads!(association_name = nil, *source_models)
    source_models = source_models.compact
    wrong_combinations = source_models.combination(source_models.size - 1)

    wrong_combinations.each do |wrong_combination|
      quick_create!(association_name, *wrong_combination, allow_no_source: true)
    end

    quick_create!(association_name, *source_models, allow_no_source: true, skip_default: true)
  end
end
