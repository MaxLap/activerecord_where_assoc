# frozen_string_literal: true

# Things to check:
# * Poly or not
# * With and without condition
# * has_one and has_one
# * different :source
# * default_scopes

require_relative "base_test_model"

# Classes are names S0, S1, S2... for "Step"
# Relations are names m1, o2, b3 for "Many", "One", "Belong" and the id of the next step
# A class always point further down to the next steps

class S0 < BaseTestRecord
  testable_has_many :m1, class_name: "S1"
  has_one :o1, class_name: "S1"
  belongs_to :b1, class_name: "S1"

  testable_has_many :m2m1, through: :m1, source: :m2, class_name: "S2"
  has_one :o2o1, through: :o1, source: :o2, class_name: "S2"

  # 2 different ways of doing 3 steps:
  # one through after the other
  testable_has_many :m3m2m1, through: :m2m1, source: :m3, class_name: "S3"
  has_one :o3o2o1, through: :o2o1, source: :o3, class_name: "S3"

  # one through with a source that uses another through
  testable_has_many :m3m1_m3m2, through: :m1, source: :m3m2, class_name: "S3"
  has_one :o3o1_o3o2, through: :o1, source: :o3o2, class_name: "S3"
end

class S1 < BaseTestRecord
  testable_has_many :m2, class_name: "S2"
  has_one :o2, class_name: "S2"
  belongs_to :b2, class_name: "S2"

  testable_has_many :m3m2, through: :m2, source: :m3, class_name: "S3"
  has_one :o3o2, through: :o2, source: :o3, class_name: "S3"
end

class S2 < BaseTestRecord
  testable_has_many :m3, class_name: "S3"
  has_one :o3, class_name: "S3"
  belongs_to :b3, class_name: "S3"
end

class S3 < BaseTestRecord
end
