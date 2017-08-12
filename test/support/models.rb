# frozen_string_literal: true

# Things to check:
# * Poly or not
# * With and without condition
# * testable_has_one and testable_has_one
# * different :source
# * default_scopes

require_relative "base_test_model"

# Classes are names S0, S1, S2... for "Step"
# Relations are names m1, o2, b3 for "Many", "One", "Belong" and the id of the next step
# A class always point further down to the next steps

class S0 < BaseTestRecord
  testable_has_many :m1, class_name: "S1"
  testable_has_one :o1, -> { order("s1s.id DESC") }, class_name: "S1"
  testable_belongs_to :b1, class_name: "S1", foreign_key: "s1_id"
  testable_has_and_belongs_to_many :z1, class_name: "S1"

  testable_has_many :m2m1, through: :m1, source: :m2, class_name: "S2"
  testable_has_many :m2o1, through: :o1, source: :m2, class_name: "S2"
  testable_has_many :m2b1, through: :b1, source: :m2, class_name: "S2"
  testable_has_many :m2z1, through: :z1, source: :m2, class_name: "S2"
  testable_has_one :o2m1, -> { order("s2s.id DESC") }, through: :m1, source: :o2, class_name: "S2"
  testable_has_one :o2o1, -> { order("s2s.id DESC") }, through: :o1, source: :o2, class_name: "S2"
  testable_has_one :o2b1, -> { order("s2s.id DESC") }, through: :b1, source: :o2, class_name: "S2"
  testable_has_one :o2z1, -> { order("s2s.id DESC") }, through: :z1, source: :o2, class_name: "S2"

  # 2 different ways of doing 3 steps:
  # one through after the other
  testable_has_many :m3m2m1, through: :m2m1, source: :m3, class_name: "S3"
  testable_has_one :o3o2o1, -> { order("s3s.id DESC") }, through: :o2o1, source: :o3, class_name: "S3"

  # one through with a source that uses another through
  testable_has_many :m3m1_m3m2, through: :m1, source: :m3m2, class_name: "S3"
  testable_has_one :o3o1_o3o2, -> { order("s3s.id DESC") }, through: :o1, source: :o3o2, class_name: "S3"
end

class S1 < BaseTestRecord
  testable_has_many :m2, class_name: "S2"
  testable_has_one :o2, -> { order("s2s.id DESC") }, class_name: "S2"
  testable_belongs_to :b2, class_name: "S2"
  testable_has_and_belongs_to_many :z2, class_name: "S2"

  testable_has_many :m3m2, through: :m2, source: :m3, class_name: "S3"
  testable_has_many :m3o2, through: :o2, source: :m3, class_name: "S3"
  testable_has_many :m3b2, through: :b2, source: :m3, class_name: "S3"
  testable_has_many :m3z2, through: :z2, source: :m3, class_name: "S3"
  testable_has_one :o3m2, -> { order("s3s.id DESC") }, through: :m2, source: :o3, class_name: "S3"
  testable_has_one :o3o2, -> { order("s3s.id DESC") }, through: :o2, source: :o3, class_name: "S3"
  testable_has_one :o3b2, -> { order("s3s.id DESC") }, through: :b2, source: :o3, class_name: "S3"
  testable_has_one :o3z2, -> { order("s3s.id DESC") }, through: :z2, source: :o3, class_name: "S3"

  scope :adhoc_is_one, -> { where(adhoc_column_name => 1) }
  scope :adhoc_is_two, -> { where(adhoc_column_name => 2) }
end

class S2 < BaseTestRecord
  testable_has_many :m3, class_name: "S3"
  testable_has_one :o3, class_name: "S3"
  testable_belongs_to :b3, class_name: "S3"
  testable_has_and_belongs_to_many :z3, class_name: "S3"
end

class S3 < BaseTestRecord
end


class SchemaS0 < ActiveRecord::Base
  self.table_name = "foo_schema.schema_s0s"
  belongs_to :b1, class_name: "SchemaS1", foreign_key: "schema_s1_id"
  has_many :m1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
  has_one :o1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
  has_and_belongs_to_many :z1, class_name: "SchemaS1", join_table: "spam_schema.schema_s0s_schema_s1s"
end

class SchemaS1 < ActiveRecord::Base
  self.table_name = "bar_schema.schema_s1s"
end
