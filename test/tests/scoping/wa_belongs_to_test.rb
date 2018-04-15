# frozen_string_literal: true

require_relative "../../test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "finds the right matching belongs_tos" do
    s0_1 = s0
    s0_1.create_assoc!(:b1, :S0_b1)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:b1, :S0_b1)

    _s0_4 = S0.create_default!

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
