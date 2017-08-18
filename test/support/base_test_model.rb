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
    condition = other.testable_condition(value)
    other.send(:default_scope, -> { where(condition) })
  end

  def self.test_condition_column
    "#{table_name}_column"
  end
  delegate :test_condition_column, to: "self.class"

  def self.adhoc_column_name
    "#{table_name}_adhoc_column"
  end
  delegate :adhoc_column_name, to: "self.class"

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

  # Creates an association with a condition on #{target_table_name}.#{target_table_name}_column
  def self.testable_association(macro, association_name, given_scope = nil, options = {})
    if given_scope.is_a?(Hash)
      options = given_scope
      given_scope = nil
    end

    condition_value = test_condition_value_for(association_name)
    if given_scope
      scope = -> { where(testable_condition(condition_value)).instance_exec(&given_scope) }
    else
      scope = -> { where(testable_condition(condition_value)) }
    end

    send(macro, association_name, scope, options)
  end

  def self.testable_has_many(association_name, given_scope = nil, options = {})
    raise "association_name should start with 'm'" unless association_name.to_s.start_with?("m")
    testable_association(:has_many, association_name, given_scope, options)
  end

  def self.testable_has_one(association_name, given_scope = nil, options = {})
    raise "association_name should start with 'o'" unless association_name.to_s.start_with?("o")
    testable_association(:has_one, association_name, given_scope, options)
  end

  def self.testable_belongs_to(association_name, given_scope = nil, options = {})
    raise "association_name should start with 'b'" unless association_name.to_s.start_with?("b")
    testable_association(:belongs_to, association_name, given_scope, options)
  end

  def self.testable_has_and_belongs_to_many(association_name, given_scope = nil, options = {})
    raise "association_name should start with 'z'" unless association_name.to_s.start_with?("z")
    testable_association(:has_and_belongs_to_many, association_name, given_scope, options)
  end

  def self.create_default!(*source_associations)
    condition_value = TestHelpers.condition_value_result_for(*source_associations) || 1
    condition_value *= test_condition_value_for(:default_scope)
    create!(test_condition_column => condition_value)
  end

  # does a #create! and automatically fills the column with a value that matches the merge of the condition on
  # the matching association of each passed source_associations
  def create_assoc!(association_name, *source_associations, allow_no_source: false,
                    adhoc_value: nil, skip_default: false, use_bad_type: false)
    raise "Must be a direct association, not #{association_name.inspect}" unless association_name =~ /^[mobz]p?\d+$/

    if !allow_no_source && source_associations.empty?
      raise "Need at least one source model or a nil instead"
    end
    source_associations = source_associations.compact
    association_name = ActiveRecordWhereAssoc::Helpers.normalize_association_name(association_name)
    association_macro = association_name.to_s[/^[a-z]+/]

    reflection = self.class.reflections[association_name]
    raise "Didn't find association: #{association_name}" unless reflection

    target_model = reflection.klass

    if !skip_default && target_model.test_condition_value_for?(:default_scope)
      condition_value = target_model.test_condition_value_for(:default_scope)
    end

    if source_associations.present?
      condition_value ||= 1
      condition_value *= TestHelpers.condition_value_result_for(*source_associations)
    end

    attributes = { target_model.test_condition_column => condition_value,
                   target_model.adhoc_column_name => adhoc_value,
    }
    case association_macro
    when "m", "z", "mp"
      record = send(association_name).create!(attributes)
    when "o", "op"
      # Creating a has_one like this removes the id of the previously existing records that were refering.
      # We don't want that for the purpose of our tests
      old_matched_ids = target_model.where(reflection.foreign_key => self.id).pluck(:id)
      record = send("create_#{association_name}!", attributes)
      target_model.where(id: old_matched_ids).update_all(reflection.foreign_key => self.id)
    when "b"
      record = send("create_#{association_name}!", attributes)
      save! # Must save that our id that just changed
    else
      raise "Unexpected macro: #{association_macro}"
    end

    if use_bad_type
      case association_macro
      when "mp", "op"
        record.update_attributes(:"has_#{record.class.table_name}_poly_type" => "PolyBadRecord")
      when "bp"
        update_attributes(:"#{self.class.table_name}_belongs_to_poly_type" => "PolyBadRecord")
      end

    end

    record
  end

  # Receives the same parameters as #create_assoc!, but creates a record for every
  # combinations missing one of the source models and the default scope
  def create_bad_assocs!(association_name, *source_associations, &block)
    source_models = source_associations.compact
    assocs_options = []

    wrong_combinations = source_associations.combination(source_associations.size - 1)
    wrong_combinations.each do |wrong_combination|
      assocs_options << [association_name, *wrong_combination, allow_no_source: true]
    end

    assocs_options << [association_name, *source_models, allow_no_source: true, skip_default: true]

    if association_name =~ /^.p\d/
      assocs_options << [association_name, *source_models, allow_no_source: true, use_bad_type: true]
    end

    records = []

    assocs_options.each do |assoc_options|
      records << create_assoc!(*assoc_options)
      if block
        yield records.last
        records.last.destroy
      end
    end

    if block
      nil
    else
      records
    end
  end
end
