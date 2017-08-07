# frozen_string_literal: true

require "test_helper"

describe "wa_exists" do
  let(:s0) { S0.create_default! }

  it "always returns no result for belongs_to if no possible ones exists" do
    assert_equal [], S0.where_assoc_exists(:b1)
    assert_equal [], S0.where_assoc_not_exists(:b1)
    b1 = S1.create!(S1.test_condition_column => S0.test_condition_value_for(:b1) * S1.test_condition_value_for(:default_scope))
    assert_equal [], S0.where_assoc_exists(:b1)
    assert_equal [], S0.where_assoc_not_exists(:b1)

    # Making sure the S1 was valid according to the scopes by creating the S0 and
    # setting up the association with the existing S1
    s0.update_attributes!(s1_id: b1.id)
    assert_exists_with_matching(:b1)
  end

  it "finds a matching belongs_to" do
    s0.create_assoc!(:b1, :S0_b1)

    assert_exists_with_matching(:b1)
  end

  it "doesn't find a non matching belongs_to" do
    s0.create_bad_assocs!(:b1, :S0_b1)

    assert_exists_without_matching(:b1)
  end

  it "finds a matching has_many through belongs_to" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_assoc!(:m2, :S0_m2b1, :S1_m2)

    assert_exists_with_matching(:m2b1)
  end

  it "doesn't find a non matching has_many through belongs_to" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_bad_assocs!(:m2, :S0_m2b1, :S1_m2)

    assert_exists_without_matching(:m2b1)
  end

  it "finds a matching has_many through belongs_to using an array for the association" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_assoc!(:m2, :S1_m2)

    assert_exists_with_matching([:b1, :m2])
  end

  it "doesn't find a non matching has_many through belongs_to using an array for the association" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_bad_assocs!(:m2, :S1_m2)

    assert_exists_without_matching([:b1, :m2])
  end
end
