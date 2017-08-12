# frozen_string_literal: true

require "test_helper"

describe "wa_count" do
  let(:s0) { S0.create_default! }

  it "always returns no result for has_and_belongs_to_many if no possible ones exists" do
    assert_equal [], S0.where_assoc_exists(:z1)
    assert_equal [], S0.where_assoc_not_exists(:z1)
    S1.create!(S1.test_condition_column => S0.test_condition_value_for(:z1))
    assert_equal [], S0.where_assoc_exists(:z1)
    assert_equal [], S0.where_assoc_not_exists(:z1)
  end

  it "finds a matching has_and_belongs_to_many" do
    s0.create_assoc!(:z1, :S0_z1)
    s0.create_assoc!(:z1, :S0_z1)

    assert_wa_count(2, :z1)
  end

  it "doesn't find a non matching has_and_belongs_to_many" do
    s0.create_bad_assocs!(:z1, :S0_z1)

    assert_wa_count(0, :z1)
  end

  it "finds a matching has_many through has_and_belongs_to_many" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_assoc!(:m2, :S0_m2z1, :S1_m2)
    z1.create_assoc!(:m2, :S0_m2z1, :S1_m2)

    assert_wa_count(2, :m2z1)
  end

  it "doesn't find a non matching has_many through has_and_belongs_to_many" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_bad_assocs!(:m2, :S0_m2z1, :S1_m2)

    assert_wa_count(0, :m2z1)
  end

  it "finds a matching has_many through has_and_belongs_to_many using an array for the association" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_assoc!(:m2, :S1_m2)
    z1.create_assoc!(:m2, :S1_m2)

    assert_wa_count(2, [:z1, :m2])
  end

  it "doesn't find a non matching has_many through has_and_belongs_to_many using an array for the association" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_bad_assocs!(:m2, :S1_m2)

    assert_wa_count(0, [:z1, :m2])
  end
end
