# frozen_string_literal: true

require "test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "always returns no result for has_many if no possible ones exists" do
    assert !S0.where_assoc_count(1, :==, :m1).exists?
    assert !S0.where_assoc_count(1, :!=, :m1).exists?
    assert !S0.where_assoc_exists(:m1).exists?
    assert !S0.where_assoc_not_exists(:m1).exists?
    m1 = S1.create!(S1.test_condition_column => S0.test_condition_value_for(:m1) * S1.test_condition_value_for(:default_scope))
    assert !S0.where_assoc_count(1, :==, :m1).exists?
    assert !S0.where_assoc_count(1, :!=, :m1).exists?
    assert !S0.where_assoc_exists(:m1).exists?
    assert !S0.where_assoc_not_exists(:m1).exists?

    # Making sure the S1 was valid according to the scopes by creating the S0 and
    # setting up the association with the existing S1
    m1.update_attributes!(s0_id: s0.id)
    assert_wa(1, :m1)
  end

  it "finds the right matching has_manys" do
    s0_1 = s0
    s0_1.create_assoc!(:m1, :S0_m1)

    s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:m1, :S0_m1)

    s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :m1).to_a.sort_by(&:id)
  end

  it "finds a matching has_many" do
    s0.create_assoc!(:m1, :S0_m1)
    s0.create_assoc!(:m1, :S0_m1)

    assert_wa(2, :m1)
  end

  it "doesn't find without any has_many" do
    s0
    assert_wa(0, :m1)
  end

  it "doesn't find with a non matching has_many" do
    s0.create_bad_assocs!(:m1, :S0_m1)

    assert_wa(0, :m1)
  end

  it "finds a matching has_many through has_many" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m1.create_assoc!(:m2, :S0_m2m1, :S1_m2)
    m1.create_assoc!(:m2, :S0_m2m1, :S1_m2)

    assert_wa(2, :m2m1)
  end

  it "doesn't find without any has_many through has_many" do
    s0
    assert_wa(0, :m2m1)
  end

  it "doesn't find with a non matching has_many through has_many" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m1.create_bad_assocs!(:m2, :S0_m2m1, :S1_m2)

    assert_wa(0, :m2m1)
  end

  it "finds a matching has_many through has_many using an array for the association" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m1.create_assoc!(:m2, :S1_m2)
    m1.create_assoc!(:m2, :S1_m2)

    assert_wa(2, [:m1, :m2])
  end

  it "doesn't find without any has_many through has_many using an array for the association" do
    s0
    assert_wa(0, [:m1, :m2])
  end

  it "doesn't find with a non matching has_many through has_many using an array for the association" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m1.create_bad_assocs!(:m2, :S1_m2)

    assert_wa(0, [:m1, :m2])
  end

  it "finds a matching has_many through has_many through has_many" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m2 = m1.create_assoc!(:m2, :S0_m2m1, :S1_m2)
    m2.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)

    assert_wa(2, :m3m2m1)
  end

  it "doesn't find without any has_many through has_many through has_many" do
    s0
    assert_wa(0, :m3m2m1)
  end

  it "doesn't find with a non matching has_many through has_many through has_many" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m2 = m1.create_assoc!(:m2, :S0_m2m1, :S1_m2)
    m2.create_bad_assocs!(:m3, :S0_m3m2m1, :S2_m3)

    assert_wa(0, :m3m2m1)
  end

  it "finds a matching has_many through a has_many with a source that is a has_many through" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m2 = m1.create_assoc!(:m2, :S1_m2)
    m2.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)

    assert_wa(2, :m3m1_m3m2)
  end

  it "doesn't find without any has_many through a has_many with a source that is a has_many through" do
    s0
    assert_wa(0, :m3m1_m3m2)
  end

  it "doesn't find with a non matching has_many through a has_many with a source that is a has_many through" do
    m1 = s0.create_assoc!(:m1, :S0_m1)
    m2 = m1.create_assoc!(:m2, :S1_m2)
    m2.create_bad_assocs!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)

    assert_wa(0, :m3m1_m3m2)
  end
end
