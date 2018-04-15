# frozen_string_literal: true

require_relative "../../test_helper"

describe "wa" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  let(:s0) { S0.create_default! }

  it "finds the right matching has_ones" do
    s0_1 = s0
    s0_1.create_assoc!(:o1, :S0_o1)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:o1, :S0_o1)

    _s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :o1).to_a.sort_by(&:id)
  end

  it "finds a matching has_one" do
    s0.create_assoc!(:o1, :S0_o1)
    s0.create_assoc!(:o1, :S0_o1)

    assert_wa(1, :o1)
  end

  it "doesn't find without any has_one" do
    s0
    assert_wa(0, :o1)
  end

  it "doesn't find with a non matching has_one" do
    s0.create_bad_assocs!(:o1, :S0_o1)

    assert_wa(0, :o1)
  end

  it "finds a matching has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)

    assert_wa(1, :o2o1)
  end

  it "doesn't find without any has_one through has_one" do
    s0
    assert_wa(0, :o2o1)
  end

  it "doesn't find with a non matching has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_bad_assocs!(:o2, :S0_o2o1, :S1_o2)

    assert_wa(0, :o2o1)
  end

  it "finds a matching has_one through has_one using an array for the association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S1_o2)
    o1.create_assoc!(:o2, :S1_o2)

    assert_wa(1, [:o1, :o2])
  end

  it "doesn't find without any has_one through has_one using an array for the association" do
    s0
    assert_wa(0, [:o1, :o2])
  end

  it "doesn't find with a non matching has_one through has_one using an array for the association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_bad_assocs!(:o2, :S1_o2)

    assert_wa(0, [:o1, :o2])
  end

  it "finds a matching has_one through has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)
    o2.create_assoc!(:o3, :S0_o3o2o1, :S2_o3)

    assert_wa(1, :o3o2o1)
  end

  it "doesn't find without any has_one through has_one through has_one" do
    s0
    assert_wa(0, :o3o2o1)
  end

  it "doesn't find with a non matching has_one through has_one through has_one" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    o2.create_bad_assocs!(:o3, :S0_o3o2o1, :S2_o3)

    assert_wa(0, :o3o2o1)
  end

  it "finds a matching has_one through a has_one with a source that is a has_one through" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S1_o2)
    o2.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)
    o2.create_assoc!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)

    assert_wa(1, :o3o1_o3o2)
  end

  it "doesn't find without any has_one through a has_one with a source that is a has_one through" do
    s0
    assert_wa(0, :o3o1_o3o2)
  end

  it "doesn't find with a non matching has_one through a has_one with a source that is a has_one through" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o2 = o1.create_assoc!(:o2, :S1_o2)
    o2.create_bad_assocs!(:o3, :S0_o3o1_o3o2, :S1_o3o2, :S2_o3)

    assert_wa(0, :o3o1_o3o2)
  end
end
