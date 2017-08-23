# frozen_string_literal: true

require "test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "finds the right matching poly has_manys" do
    s0_1 = s0
    s0_1.create_assoc!(:mp1, :S0_mp1)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:mp1, :S0_mp1)

    _s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :mp1).to_a.sort_by(&:id)
  end

  it "finds a matching poly has_many" do
    s0.create_assoc!(:mp1, :S0_mp1)
    s0.create_assoc!(:mp1, :S0_mp1)

    assert_wa(2, :mp1)
  end

  it "doesn't find without any poly has_many" do
    s0
    assert_wa(0, :mp1)
  end

  it "doesn't find with a non matching poly has_many" do
    s0.create_bad_assocs!(:mp1, :S0_mp1)

    assert_wa(0, :mp1)
  end

  it "finds a matching poly has_many through poly has_many" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp1.create_assoc!(:mp2, :S0_mp2mp1, :S1_mp2)
    mp1.create_assoc!(:mp2, :S0_mp2mp1, :S1_mp2)

    assert_wa(2, :mp2mp1)
  end

  it "doesn't find without any poly has_many through poly has_many" do
    s0
    assert_wa(0, :mp2mp1)
  end

  it "doesn't find with a non matching poly has_many through poly has_many" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp1.create_bad_assocs!(:mp2, :S0_mp2mp1, :S1_mp2)

    assert_wa(0, :mp2mp1)
  end

  it "finds a matching poly has_many through poly has_many using an array for the association" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp1.create_assoc!(:mp2, :S1_mp2)
    mp1.create_assoc!(:mp2, :S1_mp2)

    assert_wa(2, [:mp1, :mp2])
  end

  it "doesn't find without any poly has_many through poly has_many using an array for the association" do
    s0
    assert_wa(0, [:mp1, :mp2])
  end

  it "doesn't find with a non matching poly has_many through poly has_many using an array for the association" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp1.create_bad_assocs!(:mp2, :S1_mp2)

    assert_wa(0, [:mp1, :mp2])
  end

  it "finds a matching poly has_many through poly has_many through poly has_many" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp2 = mp1.create_assoc!(:mp2, :S0_mp2mp1, :S1_mp2)
    mp2.create_assoc!(:mp3, :S0_mp3mp2mp1, :S2_mp3)
    mp2.create_assoc!(:mp3, :S0_mp3mp2mp1, :S2_mp3)

    assert_wa(2, :mp3mp2mp1)
  end

  it "doesn't find without any poly has_many through poly has_many through poly has_many" do
    s0
    assert_wa(0, :mp3mp2mp1)
  end

  it "doesn't find with a non matching poly has_many through poly has_many through poly has_many" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp2 = mp1.create_assoc!(:mp2, :S0_mp2mp1, :S1_mp2)
    mp2.create_bad_assocs!(:mp3, :S0_mp3mp2mp1, :S2_mp3)

    assert_wa(0, :mp3mp2mp1)
  end

  it "finds a matching poly has_many through a poly has_many with a source that is a poly has_many through" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp2 = mp1.create_assoc!(:mp2, :S1_mp2)
    mp2.create_assoc!(:mp3, :S0_mp3mp1_mp3mp2, :S1_mp3mp2, :S2_mp3)
    mp2.create_assoc!(:mp3, :S0_mp3mp1_mp3mp2, :S1_mp3mp2, :S2_mp3)

    assert_wa(2, :mp3mp1_mp3mp2)
  end

  it "doesn't find without any poly has_many through a poly has_many with a source that is a poly has_many through" do
    s0
    assert_wa(0, :mp3mp1_mp3mp2)
  end

  it "doesn't find with a non matching poly has_many through a poly has_many with a source that is a poly has_many through" do
    mp1 = s0.create_assoc!(:mp1, :S0_mp1)
    mp2 = mp1.create_assoc!(:mp2, :S1_mp2)
    mp2.create_bad_assocs!(:mp3, :S0_mp3mp1_mp3mp2, :S1_mp3mp2, :S2_mp3)

    assert_wa(0, :mp3mp1_mp3mp2)
  end
end
