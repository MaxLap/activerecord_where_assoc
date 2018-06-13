# frozen_string_literal: true

# Things to check:
# * Poly or not
# * With and without condition
# * testable_has_one and testable_has_one
# * different :source
# * default_scopes

require_relative "base_test_model"

# Classes are names S0, S1, S2... for "Step"
# Associations are names m1, o2, b3 for "Many", "One", "Belong" and the id of the next step
# Associations with 'p' in the middle of the name, like mp1, op1, bp1 are polymorphic
# A class always point further down to the next steps

class S0 < BaseTestModel
  setup_test_default_scope

  testable_has_many :m1, class_name: "S1"
  testable_has_one :o1, -> { order("s1s.id DESC") }, class_name: "S1"
  testable_belongs_to :b1, class_name: "S1", foreign_key: "s1_id"
  testable_has_and_belongs_to_many :z1, class_name: "S1"

  testable_has_many :mp1, class_name: "S1", as: "has_s1s_poly"
  testable_has_one :op1, -> { order("s1s.id DESC") }, class_name: "S1", as: "has_s1s_poly"
  testable_belongs_to :bp1, polymorphic: true, foreign_key: "s0s_belongs_to_poly_id", foreign_type: "s0s_belongs_to_poly_type"

  testable_has_many :m2m1, through: :m1, source: :m2, class_name: "S2"
  testable_has_many :m2o1, through: :o1, source: :m2, class_name: "S2"
  testable_has_many :m2b1, through: :b1, source: :m2, class_name: "S2"
  testable_has_many :m2z1, through: :z1, source: :m2, class_name: "S2"

  testable_has_one :o2m1, -> { order("s2s.id DESC") }, through: :m1, source: :o2, class_name: "S2"
  testable_has_one :o2o1, -> { order("s2s.id DESC") }, through: :o1, source: :o2, class_name: "S2"
  testable_has_one :o2b1, -> { order("s2s.id DESC") }, through: :b1, source: :o2, class_name: "S2"

  testable_has_one :o2z1, -> { order("s2s.id DESC") }, through: :z1, source: :o2, class_name: "S2"
  testable_has_one :ob2b1, -> { order("s2s.id DESC") }, through: :b1, source: :b2, class_name: "S2"

  testable_has_many :mp2mp1, through: :mp1, source: :mp2, class_name: "S2"
  testable_has_many :mp2op1, through: :op1, source: :mp2, class_name: "S2"
  testable_has_one :op2mp1, -> { order("s2s.id DESC") }, through: :mp1, source: :op2, class_name: "S2"
  testable_has_one :op2op1, -> { order("s2s.id DESC") }, through: :op1, source: :op2, class_name: "S2"

  # 2 different ways of doing 3 steps:
  # one through after the other
  testable_has_many :m3m2m1, through: :m2m1, source: :m3, class_name: "S3"
  testable_has_one :o3o2o1, -> { order("s3s.id DESC") }, through: :o2o1, source: :o3, class_name: "S3"

  testable_has_many :mp3mp2mp1, through: :mp2mp1, source: :mp3, class_name: "S3"
  testable_has_one :op3op2op1, -> { order("s3s.id DESC") }, through: :op2op1, source: :op3, class_name: "S3"

  # one through with a source that uses another through
  testable_has_many :m3m1_m3m2, through: :m1, source: :m3m2, class_name: "S3"
  testable_has_one :o3o1_o3o2, -> { order("s3s.id DESC") }, through: :o1, source: :o3o2, class_name: "S3"

  testable_has_many :mp3mp1_mp3mp2, through: :mp1, source: :mp3mp2, class_name: "S3"
  testable_has_one :op3op1_op3op2, -> { order("s3s.id DESC") }, through: :op1, source: :op3op2, class_name: "S3"

  belongs_to :schema_b1, class_name: "SchemaS1", foreign_key: "s1_id"
  has_many :schema_m1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
  has_one :schema_o1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
end

class S1 < BaseTestModel
  setup_test_default_scope

  testable_has_many :m2, class_name: "S2"
  testable_has_one :o2, -> { order("s2s.id DESC") }, class_name: "S2"
  testable_belongs_to :b2, class_name: "S2", foreign_key: "s2_id"
  testable_has_and_belongs_to_many :z2, class_name: "S2"

  testable_has_many :mp2, class_name: "S2", as: "has_s2s_poly"
  testable_has_one :op2, -> { order("s2s.id DESC") }, class_name: "S2", as: "has_s2s_poly"
  testable_belongs_to :bp2, polymorphic: true, foreign_key: "s1s_belongs_to_poly_id", foreign_type: "s1s_belongs_to_poly_type"

  testable_has_many :m3m2, through: :m2, source: :m3, class_name: "S3"
  testable_has_many :m3o2, through: :o2, source: :m3, class_name: "S3"
  testable_has_many :m3b2, through: :b2, source: :m3, class_name: "S3"
  testable_has_many :m3z2, through: :z2, source: :m3, class_name: "S3"
  testable_has_one :o3m2, -> { order("s3s.id DESC") }, through: :m2, source: :o3, class_name: "S3"
  testable_has_one :o3o2, -> { order("s3s.id DESC") }, through: :o2, source: :o3, class_name: "S3"
  testable_has_one :o3b2, -> { order("s3s.id DESC") }, through: :b2, source: :o3, class_name: "S3"
  testable_has_one :o3z2, -> { order("s3s.id DESC") }, through: :z2, source: :o3, class_name: "S3"

  testable_has_many :mp3mp2, through: :mp2, source: :mp3, class_name: "S3"
  testable_has_many :mp3op2, through: :op2, source: :mp3, class_name: "S3"
  testable_has_one :op3mp2, -> { order("s3s.id DESC") }, through: :mp2, source: :op3, class_name: "S3"
  testable_has_one :op3op2, -> { order("s3s.id DESC") }, through: :op2, source: :op3, class_name: "S3"

  scope :adhoc_is_one, -> { where(adhoc_column_name => 1) }
  scope :adhoc_is_two, -> { where(adhoc_column_name => 2) }
end

class S2 < BaseTestModel
  setup_test_default_scope

  testable_has_many :m3, class_name: "S3"
  testable_has_one :o3, -> { order("s3s.id DESC") }, class_name: "S3"
  testable_belongs_to :b3, class_name: "S3"
  testable_has_and_belongs_to_many :z3, class_name: "S3"

  testable_has_many :mp3, class_name: "S3", as: "has_s3s_poly"
  testable_has_one :op3, -> { order("s3s.id DESC") }, class_name: "S3", as: "has_s3s_poly"
  testable_belongs_to :bp3, polymorphic: true, foreign_key: "s2s_belongs_to_poly_id", foreign_type: "s2s_belongs_to_poly_type"
end

class S3 < BaseTestModel
  setup_test_default_scope
end

class PolyBadRecord < BaseTestModel
  # Used for testing polymorphic associations
end

class SchemaS0 < BaseTestModel
  self.table_name = "foo_schema.schema_s0s"
  belongs_to :schema_b1, class_name: "SchemaS1", foreign_key: "schema_s1_id"
  has_many :schema_m1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
  has_one :schema_o1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
  has_and_belongs_to_many :schema_z1, class_name: "SchemaS1", join_table: "spam_schema.schema_s0s_schema_s1s"

  belongs_to :b1, class_name: "S1", foreign_key: "schema_s1_id"
  has_many :m1, class_name: "S1", foreign_key: "s0_id"
  has_one :o1, class_name: "S1", foreign_key: "s0_id"
end

class SchemaS1 < BaseTestModel
  self.table_name = "bar_schema.schema_s1s"

  belongs_to :schema_b2, class_name: "SchemaS2", foreign_key: "schema_s2_id"
  has_many :schema_m2, class_name: "SchemaS2", foreign_key: "schema_s1_id"
  has_one :schema_o2, class_name: "SchemaS2", foreign_key: "schema_s1_id"

  belongs_to :b2, class_name: "S2", foreign_key: "schema_s2_id"
  has_many :m2, class_name: "S2", foreign_key: "schema_s1_id"
  has_one :o2, class_name: "S2", foreign_key: "schema_s1_id"
end

class SchemaS2 < BaseTestModel
  self.table_name = "bar_schema.schema_s2s"
end


class STIS0 < BaseTestModel
  self.table_name = "sti_s0s"
  belongs_to :b1, class_name: "STIS1", foreign_key: "sti_s1_id"
  belongs_to :b1sub, class_name: "STIS1Sub", foreign_key: "sti_s1_id"
  has_many :m1, class_name: "STIS1", foreign_key: "sti_s0_id"
  has_many :m1sub, class_name: "STIS1Sub", foreign_key: "sti_s0_id"
  has_one :o1, class_name: "STIS1", foreign_key: "sti_s0_id"
  has_one :o1sub, class_name: "STIS1Sub", foreign_key: "sti_s0_id"
  has_and_belongs_to_many :z1, class_name: "STIS1", join_table: "sti_s0s_sti_s1s", foreign_key: "sti_s0_id", association_foreign_key: "sti_s1_id"
  has_and_belongs_to_many :z1sub, class_name: "STIS1Sub",
                                  join_table: "sti_s0s_sti_s1s",
                                  foreign_key: "sti_s0_id",
                                  association_foreign_key: "sti_s1_id"

  has_many :mp1, class_name: "STIS1", as: "sti_s0"
  has_one :op1, class_name: "STIS1", as: "sti_s0"
end

class STIS0Sub < STIS0
  has_many :mp1_from_sub, class_name: "STIS1", as: "sti_s0"
  has_one :op1_from_sub, class_name: "STIS1", as: "sti_s0"
end

class STIS0SubSub < STIS0Sub
end

class STIS1 < BaseTestModel
  self.table_name = "sti_s1s"
end

class STIS1Sub < STIS1
end

# LEW for Last Equality Wins
class LEWS0 < BaseTestModel
  self.table_name = "lew_s0s"
  has_many :m1, -> { where(lew_s1s_column: "has_many") }, class_name: "LEWS1", foreign_key: "lew_s0_id"
  has_one :o1, -> { where(lew_s1s_column: "has_one").order(:id) }, class_name: "LEWS1", foreign_key: "lew_s0_id"
  belongs_to :b1, -> { where(lew_s1s_column: "belongs_to") }, class_name: "LEWS1", foreign_key: "lew_s1_id"
  has_and_belongs_to_many :z1, -> { where(lew_s1s_column: "habtm") }, class_name: "LEWS1",
                                                                      join_table: "lew_s0s_lew_s1s",
                                                                      foreign_key: "lew_s0_id",
                                                                      association_foreign_key: "lew_s1_id"
end

class LEWS1 < BaseTestModel
  self.table_name = "lew_s1s"
  default_scope -> { where(lew_s1s_column: "default_scope") }
end


# LimOffOrd for Limit Offset Order
# default_scopes are limit(3).offset(1).order(:id)
# association_scopes with l are limit(3).offset(1).order(id desc)
# Those without the l are on the same table, without this additional scope,
# so they use the default_scope's values
#
class LimOffOrdS0 < BaseTestModel
  self.table_name = "s0s"
  belongs_to :b1, class_name: "LimOffOrdS1", foreign_key: "s1_id"
  belongs_to :bl1, -> { limit(2).offset(2).reorder("s1s.id desc") }, class_name: "LimOffOrdS1", foreign_key: "s1_id"
  has_many :m1, class_name: "LimOffOrdS1", foreign_key: "s0_id"
  has_many :ml1, -> { limit(2).offset(2).reorder("s1s.id desc") }, class_name: "LimOffOrdS1", foreign_key: "s0_id"
  has_one :o1, class_name: "LimOffOrdS1", foreign_key: "s0_id"
  has_one :ol1, -> { limit(2).offset(2).reorder("s1s.id desc") }, class_name: "LimOffOrdS1", foreign_key: "s0_id"
  has_and_belongs_to_many :z1, class_name: "LimOffOrdS1", join_table: "s0s_s1s", foreign_key: "s0_id", association_foreign_key: "s1_id"
  has_and_belongs_to_many :zl1, -> { limit(2).offset(2).reorder("s1s.id desc") }, class_name: "LimOffOrdS1",
                                                                                  join_table: "s0s_s1s",
                                                                                  foreign_key: "s0_id",
                                                                                  association_foreign_key: "s1_id"

  has_many :m2m1, class_name: "LimOffOrdS2", through: :m1, source: :m2
  has_many :m2ml1, class_name: "LimOffOrdS2", through: :ml1, source: :m2
  has_many :ml2ml1, class_name: "LimOffOrdS2", through: :ml1, source: :ml2
  has_many :l_ml2ml1, -> { limit(2).offset(2).reorder("s2s.id desc") }, class_name: "LimOffOrdS2", through: :ml1, source: :ml2
end

class LimOffOrdS1 < BaseTestModel
  self.table_name = "s1s"
  has_many :m2, class_name: "LimOffOrdS2", foreign_key: "s1_id"
  has_many :ml2, -> { limit(2).offset(2).reorder("s2s.id desc") }, class_name: "LimOffOrdS2", foreign_key: "s1_id"


  default_scope -> { limit(3).offset(1).order(:id) }
end

class LimOffOrdS2 < BaseTestModel
  self.table_name = "s2s"

  default_scope -> { limit(3).offset(1).order(:id) }
end

class RecursiveS < BaseTestModel
  belongs_to :b1, class_name: "RecursiveS", foreign_key: "belongs_id"
  has_many :m1, class_name: "RecursiveS", foreign_key: "has_id"
  has_one :o1, class_name: "RecursiveS", foreign_key: "has_id"
  has_and_belongs_to_many :z1, class_name: "RecursiveS",
                               join_table: "s0s_s1s",
                               foreign_key: "s0_id",
                               association_foreign_key: "s1_id"

  has_many :mp1, class_name: "RecursiveS", as: "has"
  has_one :op1, class_name: "RecursiveS", as: "has"
end
