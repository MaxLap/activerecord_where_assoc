# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  let(:s0) { S0.create_default! }

  it "has_one through: belongs_to, source: belongs_to doesn't use LIMIT" do
    scope = S0.where_assoc_exists(:ob2b1)
    sql = scope.to_sql
    scope.to_a # Make sure it doesn't fail
    refute_includes sql.upcase, "LIMIT"
  end

  it "has_one through: has_many, source: has_and_belongs_to_many respects the limit of the source" do
    without_manual_wa_test do
      s0 = LimOffOrdS0.create!

      s1 = s0.m1.create! # not enough to go above the offset of LimOffOrdS1's default scope

      s1.zl2.create!
      s1.zl2.create!
      s1.zl2.create!

      assert_wa_from(LimOffOrdS0, 0, :mzl2m1)

      s1 = s0.m1.create! # now it's enough to go above the offset of LimOffOrdS1's default scope

      assert_wa_from(LimOffOrdS0, 0, :mzl2m1)

      s1.zl2.create!
      s1.zl2.create! # not enough to go above zl2's offset (2)

      assert_wa_from(LimOffOrdS0, 0, :mzl2m1)

      s1.zl2.create! # it's now enough to go above zl2's offset (2)

      assert_wa_from(LimOffOrdS0, 1, :mzl2m1)
    end
  end
end
