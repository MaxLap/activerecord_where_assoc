# frozen_string_literal: true

require "test_helper"

describe "wa_count" do
  let(:s0) { S0.create_default! }

  it "always returns no result for belongs_to if no possible ones exists" do
    assert_equal [], S0.where_assoc_exists(:b1)
    assert_equal [], S0.where_assoc_not_exists(:b1)
    S1.create!(S1.test_condition_column => S0.test_condition_value_for(:b1))
    assert_equal [], S0.where_assoc_exists(:b1)
    assert_equal [], S0.where_assoc_not_exists(:b1)
  end

  it "finds a matching belongs_to" do
    s0.create_assoc!(:b1, :S0_b1)
    s0.create_assoc!(:b1, :S0_b1)

    assert_wa_count(1, :b1)
  end

  it "doesn't find a non matching belongs_to" do
    s0.create_bad_assocs!(:b1, :S0_b1)

    assert_wa_count(0, :b1)
  end

  it "finds a matching has_many through belongs_to" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_assoc!(:m2, :S0_m2b1, :S1_m2)
    b1.create_assoc!(:m2, :S0_m2b1, :S1_m2)

    assert_wa_count(2, :m2b1)
  end

  it "doesn't find a non matching has_many through belongs_to" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_bad_assocs!(:m2, :S0_m2b1, :S1_m2)

    assert_wa_count(0, :m2b1)
  end

  it "finds a matching has_many through belongs_to using an array for the association" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_assoc!(:m2, :S1_m2)
    b1.create_assoc!(:m2, :S1_m2)

    assert_wa_count(2, [:b1, :m2])
  end

  it "doesn't find a non matching has_many through belongs_to using an array for the association" do
    b1 = s0.create_assoc!(:b1, :S0_b1)
    b1.create_bad_assocs!(:m2, :S1_m2)

    assert_wa_count(0, [:b1, :m2])
  end
end
