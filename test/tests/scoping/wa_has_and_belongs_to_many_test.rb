# frozen_string_literal: true

require "test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "always returns no result for has_and_belongs_to_many if no possible ones exists" do
    assert !S0.where_assoc_count(1, :==, :z1).exists?
    assert !S0.where_assoc_count(1, :!=, :z1).exists?
    assert !S0.where_assoc_exists(:z1).exists?
    assert !S0.where_assoc_not_exists(:z1).exists?
    z1 = S1.create!(S1.test_condition_column => S0.test_condition_value_for(:z1) * S1.test_condition_value_for(:default_scope))
    assert !S0.where_assoc_count(1, :==, :z1).exists?
    assert !S0.where_assoc_count(1, :!=, :z1).exists?
    assert !S0.where_assoc_exists(:z1).exists?
    assert !S0.where_assoc_not_exists(:z1).exists?

    # Making sure the S1 was valid according to the scopes by creating the S0 and
    # setting up the association with the existing S1
    s0.z1 << z1
    assert_wa(1, :z1)
  end
  
  it "finds the right matching has_and_belongs_to_manys" do
    s0_1 = s0
    s0_1.create_assoc!(:z1, :S0_z1)

    s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:z1, :S0_z1)

    s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :z1).to_a.sort_by(&:id)
  end

  it "finds a matching has_and_belongs_to_many" do
    s0.create_assoc!(:z1, :S0_z1)
    s0.create_assoc!(:z1, :S0_z1)

    assert_wa(2, :z1)
  end

  it "doesn't find without any matching has_and_belongs_to_many" do
    s0
    assert_wa(0, :z1)
  end

  it "doesn't find with a non matching has_and_belongs_to_many" do
    s0.create_bad_assocs!(:z1, :S0_z1)

    assert_wa(0, :z1)
  end

  it "finds a matching has_many through has_and_belongs_to_many" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_assoc!(:m2, :S0_m2z1, :S1_m2)
    z1.create_assoc!(:m2, :S0_m2z1, :S1_m2)

    assert_wa(2, :m2z1)
  end

  it "doesn't find without any has_many through has_and_belongs_to_many" do
    s0
    assert_wa(0, :m2z1)
  end

  it "doesn't find with a non matching has_many through has_and_belongs_to_many" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_bad_assocs!(:m2, :S0_m2z1, :S1_m2)

    assert_wa(0, :m2z1)
  end

  it "finds a matching has_many through has_and_belongs_to_many using an array for the association" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_assoc!(:m2, :S1_m2)
    z1.create_assoc!(:m2, :S1_m2)

    assert_wa(2, [:z1, :m2])
  end

  it "doesn't find without any has_many through has_and_belongs_to_many using an array for the association" do
    s0
    assert_wa(0, [:z1, :m2])
  end

  it "doesn't find with a non matching has_many through has_and_belongs_to_many using an array for the association" do
    z1 = s0.create_assoc!(:z1, :S0_z1)
    z1.create_bad_assocs!(:m2, :S1_m2)

    assert_wa(0, [:z1, :m2])
  end
end
