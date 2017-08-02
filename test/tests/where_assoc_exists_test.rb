# frozen_string_literal: true

require "test_helper"

describe ActiveRecordWhereAssoc::QueryMethods do
  let(:s0) { S0.quick_create!(nil) }

  describe "where_assoc_exists" do
    it "always returns no result for has_many if no possible ones exists" do
      assert_equal [], S0.where_assoc_exists(:m1)
      assert_equal [], S0.where_assoc_not_exists(:m1)
      S1.create!(S1.test_condition_column => S0.test_condition_value_for(:m1))
      assert_equal [], S0.where_assoc_exists(:m1)
      assert_equal [], S0.where_assoc_not_exists(:m1)
    end

    it "finds a matching has_many" do
      s0.m1.quick_create!(:S0_m1)

      assert_exists_with_matching(:m1)
    end

    it "doesn't find a non matching has_many" do
      s0.m1.quick_creates_bads!(:S0_m1)

      assert_exists_without_matching(:m1)
    end

    it "finds a matching has_many through has_many" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m1.m2.quick_create!(:S0_m2m1, :S1_m2)

      assert_exists_with_matching(:m2m1)
    end

    it "doesn't find a non matching has_many through has_many" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m1.m2.quick_creates_bads!(:S0_m2m1, :S1_m2)

      assert_exists_without_matching(:m2m1)
    end

    it "finds a matching has_many through has_many using an array for the association" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m1.m2.quick_create!(:S1_m2)

      assert_exists_with_matching([:m1, :m2])
    end

    it "doesn't find a non matching has_many through has_many using an array for the association" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m1.m2.quick_creates_bads!(:S1_m2)

      assert_exists_without_matching([:m1, :m2])
    end

    it "finds a matching has_many through has_many through has_many" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m2 = m1.m2.quick_create!(:S0_m2m1, :S1_m2)
      m2.m3.quick_create!(:S0_m3m2m1, :S2_m3)

      assert_exists_with_matching(:m3m2m1)
    end

    it "doesn't find a non matching has_many through has_many through has_many" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m2 = m1.m2.quick_create!(:S0_m2m1, :S1_m2)
      m2.m3.quick_creates_bads!(:S0_m3m2m1, :S2_m3)

      assert_exists_without_matching(:m3m2m1)
    end

    it "finds a matching has_many through a has_many with a source that is a has_many through" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m2 = m1.m2.quick_create!(:S1_m2)
      m2.m3.quick_create!(:S0_m3m1_m3m2, :S1_m3m2, :S2_m3)

      assert_exists_with_matching(:m3m1_m3m2)
    end

    it "doesn't find a non matching has_many through a has_many with a source that is a has_many through" do
      m1 = s0.m1.quick_create!(:S0_m1)
      m2 = m1.m2.quick_create!(:S1_m2)
      m2.m3.quick_creates_bads!(:S0_m3m1_m3m2, :S1_m3m2, :S2_m3)

      assert_exists_without_matching(:m3m1_m3m2)
    end
  end

  def assert_exists_with_matching(association_name)
    msgs = []
    if !S0.where_assoc_exists(association_name).exists?
      msgs << "Expected a match but got none for S0.where_assoc_exists(#{association_name.inspect})"
    end

    if S0.where_assoc_not_exists(association_name).exists?
      msgs << "Expected no matches but got one for S0.where_assoc_not_exists(#{association_name.inspect})"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  def assert_exists_without_matching(association_name)
    msgs = []
    if S0.where_assoc_exists(association_name).exists?
      msgs << "Expected no matches but got none for S0.where_assoc_exists(#{association_name.inspect})"
    end

    if !S0.where_assoc_not_exists(association_name).exists?
      msgs << "Expected a match but got one for S0.where_assoc_not_exists(#{association_name.inspect})"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end
end
