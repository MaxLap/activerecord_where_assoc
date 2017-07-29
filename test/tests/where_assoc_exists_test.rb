# frozen_string_literal: true

require "test_helper"

describe ActiveRecordWhereAssoc::QueryMethods do
  def self.generic_test(association_path, build_from, association_sources)
    association_path = Array.wrap(association_path)
    it "finds the matching #{association_path.join(' then ')}" do
      send(build_from).send(association_path.last).quick_create!(*association_sources)

      assert_equal [tm], TM.where_assoc_exists(association_path).to_a
      assert_equal [], TM.where_assoc_not_exists(association_path).to_a
    end

    it "doesn't find the not matching #{association_path.join(' then ')}" do
      send(build_from).send(association_path.last).quick_creates_bads!(*association_sources)

      assert_equal [], TM.where_assoc_exists(association_path).to_a
      assert_equal [tm], TM.where_assoc_not_exists(association_path).to_a
    end
  end

  let(:tm) { TM.quick_create! }
  let(:hm) { tm.hms.quick_create!(TM) }
  let(:hm__through_hm) { hm.hm__through_hms.quick_create!(TM, Hm) }

  describe "where_assoc_exists" do
    generic_test :hms, :tm, [TM]
    generic_test :hm__through_hms, :hm, [TM, Hm]
    generic_test [:hms, :hm__through_hms], :hm, [Hm]
    generic_test :hm__through_hm__through_hms, :hm__through_hm, [TM, HmThroughHm]
    generic_test :hm__through_hm_with_through_hm_sources, :hm__through_hm, [TM, Hm, HmThroughHm]

    it "always returns no result if no possible ones exists" do
      assert_equal [], TM.where_assoc_exists(:hms)
      assert_equal [], TM.where_assoc_not_exists(:hms)
      Hm.create!(Hm.test_condition_column => TM.test_condition_value_for(:hms))
      assert_equal [], TM.where_assoc_exists(:hms)
      assert_equal [], TM.where_assoc_not_exists(:hms)
    end
  end
end
