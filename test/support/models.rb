# frozen_string_literal: true

# Things to check:
# * Poly or not
# * With and without condition
# * has_one and has_many
# * different :source
# * default_scopes

require_relative "base_test_model"

class TestModel < BaseTestRecord
  testable_has_many :hms
  testable_has_many :hm__through_hms, through: :hms
  testable_has_many :hm__through_hm__through_hms, through: :hm__through_hms
  testable_has_many :hm__through_hm_with_through_hm_sources, through: :hms
end
TM = TestModel


# Models below are all just relative to TestModel and ComplexTestModel
# This is especially true for the name of the associations they contain

class Hm < BaseTestRecord
  testable_has_many :hm__through_hms
  testable_has_many :hm__through_hm_with_through_hm_sources, through: :hm__through_hms
end

class HmThroughHm < BaseTestRecord
  testable_has_many :hm__through_hm__through_hms
  testable_has_many :hm__through_hm_with_through_hm_sources
end

class HmThroughHmThroughHm < BaseTestRecord
end

class HmThroughHmWithThroughHmSource < BaseTestRecord
end
