# frozen_string_literal: true

require "test_helper"

describe "wa_exists" do
  let(:s0) { S0.create_default! }

  it "always returns no result for has_and_belongs_to_many if no possible ones exists" do
    assert_equal [], S0.where_assoc_exists(:z1)
    assert_equal [], S0.where_assoc_not_exists(:z1)
    S1.create!(S1.test_condition_column => S0.test_condition_value_for(:z1) * S1.test_condition_value_for(:default_scope))
    assert_equal [], S0.where_assoc_exists(:z1)
    assert_equal [], S0.where_assoc_not_exists(:z1)
  end

  it "finds the right matching has_and_belongs_to_manys" do
    s0_1 = s0
    s0_1.create_assoc!(:z1, :S0_z1)

    s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:z1, :S0_z1)

    s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_exists(:z1).to_a.sort_by(&:id)
  end

  it "finds a matching has_and_belongs_to_many" do
    s0.create_assoc!(:z1, :S0_z1)

    assert_exists_with_matching(:z1)
  end

  it "doesn't find a non matching has_and_belongs_to_many" do
    s0.create_bad_assocs!(:z1, :S0_z1)

    assert_exists_without_matching(:z1)
  end

  it "finds a matching has_many through has_and_belongs_to_many" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_assoc!(:m2, :S0_m2z1, :S1_m2)

    assert_exists_with_matching(:m2z1)
  end

  it "doesn't find a non matching has_many through has_and_belongs_to_many" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_bad_assocs!(:m2, :S0_m2z1, :S1_m2)

    assert_exists_without_matching(:m2z1)
  end

  it "finds a matching has_many through has_and_belongs_to_many using an array for the association" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_assoc!(:m2, :S1_m2)

    assert_exists_with_matching([:z1, :m2])
  end

  it "doesn't find a non matching has_many through has_and_belongs_to_many using an array for the association" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_bad_assocs!(:m2, :S1_m2)

    assert_exists_without_matching([:z1, :m2])
  end
end
