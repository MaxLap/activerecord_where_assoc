# frozen_string_literal: true

require "test_helper"

describe ActiveRecordWhereAssoc::QueryMethods do
  let(:tm) { TM.quick_create! }
  let(:hm) { tm.hms.quick_create!(TM) }

  describe "where_assoc_exists" do
    it "always returns no result if no possible ones exists" do
      assert_equal [], TM.where_assoc_exists(:hms)
      assert_equal [], TM.where_assoc_not_exists(:hms)
      Hm.create!(Hm.test_condition_column => TM.test_condition_value_for(:hms))
      assert_equal [], TM.where_assoc_exists(:hms)
      assert_equal [], TM.where_assoc_not_exists(:hms)
    end

    it "finds the matching hms" do
      tm.hms.quick_create!(TM)

      assert_wae_existing :hms
    end

    it "doesn't find the non-matching hms" do
      tm.hms.quick_creates_bads!(TM)

      assert_wae_not_existing :hms
    end

    it "finds the mathing hm__through_hms" do
      hm.hm__through_hms.quick_create!(TM, Hm)

      assert_wae_existing :hm__through_hms
    end

    it "doesn't find the mathing hm__through_hms" do
      # Each should be refused by one of the scopes on the relations
      hm.hm__through_hms.quick_creates_bads!(TM, Hm)

      assert_wae_not_existing :hm__through_hms
    end

    it "finds the mathing hms then hm__through_hms" do
      hm.hm__through_hms.quick_create!(Hm)

      assert_wae_existing [:hms, :hm__through_hms]
    end

    it "doesn't find the mathing hms then hm__through_hms" do
      hm.hm__through_hms.quick_creates_bads!(Hm)

      assert_wae_not_existing [:hms, :hm__through_hms]
    end

    it "finds the mathing hm__through_hm__through_hms" do
      hm__through_hm = hm.hm__through_hms.quick_create!(TM, Hm)
      hm__through_hm.hm__through_hm__through_hms.quick_create!(TM, HmThroughHm)

      assert_wae_existing :hm__through_hm__through_hms
    end

    it "doesn't find the mathing hm__through_hm__through_hms" do
      hm__through_hm = hm.hm__through_hms.quick_create!(TM, Hm)
      hm__through_hm.hm__through_hm__through_hms.quick_creates_bads!(TM, HmThroughHm)

      assert_wae_not_existing :hm__through_hm__through_hms
    end

    it "finds the mathing hm__through_hm_with_through_hm_sources" do
      hm__through_hm = hm.hm__through_hms.quick_create!(Hm)
      hm__through_hm.hm__through_hm_with_through_hm_sources.quick_create!(TM, Hm, HmThroughHm)

      assert_wae_existing :hm__through_hm_with_through_hm_sources
    end

    it "doesn't find the mathing hm__through_hm_with_through_hm_sources" do
      hm__through_hm = hm.hm__through_hms.quick_create!(Hm)
      hm__through_hm.hm__through_hm_with_through_hm_sources.quick_creates_bads!(TM, Hm, HmThroughHm)

      assert_wae_not_existing :hm__through_hm_with_through_hm_sources
    end
  end

  def assert_wae_existing(*args, &block)
    assert_equal [tm], TM.where_assoc_exists(*args, &block).to_a
    assert_equal [], TM.where_assoc_not_exists(*args, &block).to_a
  end

  def assert_wae_not_existing(*args, &block)
    assert_equal [], TM.where_assoc_exists(*args, &block).to_a
    assert_equal [tm], TM.where_assoc_not_exists(*args, &block).to_a
  end
end
