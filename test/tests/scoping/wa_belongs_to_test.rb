# frozen_string_literal: true

require "test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "always returns no result for belongs_to if no possible ones exists" do
    assert !S0.where_assoc_count(1, :==, :b1).exists?
    assert !S0.where_assoc_count(1, :!=, :b1).exists?
    assert !S0.where_assoc_exists(:b1).exists?
    assert !S0.where_assoc_not_exists(:b1).exists?
    b1 = S1.create!(S1.test_condition_column => S0.test_condition_value_for(:b1) * S1.test_condition_value_for(:default_scope))
    assert !S0.where_assoc_count(1, :==, :b1).exists?
    assert !S0.where_assoc_count(1, :!=, :b1).exists?
    assert !S0.where_assoc_exists(:b1).exists?
    assert !S0.where_assoc_not_exists(:b1).exists?

    # Making sure the S1 was valid according to the scopes by creating the S0 and
    # setting up the association with the existing S1
    s0.update_attributes!(s1_id: b1.id)
    assert_wa(1, :b1)
  end

  it "finds the right matching belongs_tos" do
    s0_1 = s0
    s0_1.create_assoc!(:b1, :S0_b1)

    s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:b1, :S0_b1)

    s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :b1).to_a.sort_by(&:id)
  end

  it "finds a matching belongs_to" do
    s0.create_assoc!(:b1, :S0_b1)
    s0.create_assoc!(:b1, :S0_b1)

    assert_wa(1, :b1)
  end

  it "doesn't find without any belongs_to" do
    s0
    assert_wa(0, :b1)
  end

  it "doesn't find with a non matching belongs_to" do
    s0.create_bad_assocs!(:b1, :S0_b1)

    assert_wa(0, :b1)
  end

  it "finds a matching has_many through belongs_to" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_assoc!(:m2, :S0_m2b1, :S1_m2)
    b1.create_assoc!(:m2, :S0_m2b1, :S1_m2)

    assert_wa(2, :m2b1)
  end

  it "doesn't find without any has_many through belongs_to" do
    s0
    assert_wa(0, :m2b1)
  end

  it "doesn't find with a non matching has_many through belongs_to" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_bad_assocs!(:m2, :S0_m2b1, :S1_m2)

    assert_wa(0, :m2b1)
  end

  it "finds a matching has_many through belongs_to using an array for the association" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_assoc!(:m2, :S1_m2)
    b1.create_assoc!(:m2, :S1_m2)

    assert_wa(2, [:b1, :m2])
  end

  it "doesn't find without any has_many through belongs_to using an array for the association" do
    s0
    assert_wa(0, [:b1, :m2])
  end

  it "doesn't find with a non matching has_many through belongs_to using an array for the association" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_bad_assocs!(:m2, :S1_m2)

    assert_wa(0, [:b1, :m2])
  end
end
