# frozen_string_literal: true

require "test_helper"

describe "where_assoc_exists" do
  let(:s0) { S0.create_default! }

  it "always returns no result for has_one if no possible ones exists" do
    assert_equal [], S0.where_assoc_exists(:o1)
    assert_equal [], S0.where_assoc_not_exists(:o1)
    o1 = S1.create!(S1.test_condition_column => S0.test_condition_value_for(:o1) * S1.test_condition_value_for(:default_scope))
    assert_equal [], S0.where_assoc_exists(:o1)
    assert_equal [], S0.where_assoc_not_exists(:o1)

    # Making sure the S1 was valid according to the scopes by creating the S0 and
    # setting up the association with the existing S1
    o1.update_attributes!(s0_id: s0.id)
    assert_exists_with_matching(:o1)
  end

  it "finds a matching has_one" do
    s0.create_assoc!(:o1, :S0_o1)

    assert_exists_with_matching(:o1)
  end

  it "doesn't find a non matching has_one" do
    s0.create_bad_assocs!(:o1, :S0_o1)

    assert_exists_without_matching(:o1)
  end

  it "finds a matching has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)

    assert_exists_with_matching(:o2o1)
  end

  it "doesn't find a non matching has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_bad_assocs!(:o2, :S0_o2o1, :S1_o2)

    assert_exists_without_matching(:o2o1)
  end

  it "finds a matching has_one through has_one using an array for the association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S1_o2)

    assert_exists_with_matching([:o1, :o2])
  end

  it "doesn't find a non matching has_one through has_one using an array for the association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_bad_assocs!(:o2, :S1_o2)

    assert_exists_without_matching([:o1, :o2])
  end

  it "finds a matching has_one through has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)

    assert_exists_with_matching(:o3o2o1)
  end

  it "doesn't find a non matching has_one through has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2.create_bad_assocs!(:o3, :S0_o3o2o1, :S2_o3)

    assert_exists_without_matching(:o3o2o1)
  end

  it "finds a matching has_one through a has_one with a source that is a has_one through" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S1_o2)
    o2.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)

    assert_exists_with_matching(:o3o1_o3o2)
  end

  it "doesn't find a non matching has_one through a has_one with a source that is a has_one through" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S1_o2)
    o2.create_bad_assocs!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)

    assert_exists_without_matching(:o3o1_o3o2)
  end
end
