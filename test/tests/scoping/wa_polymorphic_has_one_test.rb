# frozen_string_literal: true

require "test_helper"

describe "wa" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  let(:s0) { S0.create_default! }

  it "finds the right matching poly has_ones" do
    s0_1 = s0
    s0_1.create_assoc!(:op1, :S0_op1)

    s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:op1, :S0_op1)

    s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :op1).to_a.sort_by(&:id)
  end

  it "finds a matching poly has_one" do
    s0.create_assoc!(:op1, :S0_op1)
    s0.create_assoc!(:op1, :S0_op1)

    assert_wa(1, :op1)
  end

  it "doesn't find without any poly has_one" do
    s0
    assert_wa(0, :op1)
  end

  it "doesn't find with a non matching poly has_one" do
    s0.create_bad_assocs!(:op1, :S0_op1)

    assert_wa(0, :op1)
  end

  it "finds a matching poly has_one through poly has_one" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op1.create_assoc!(:op2, :S0_op2op1, :S1_op2)
    op1.create_assoc!(:op2, :S0_op2op1, :S1_op2)

    assert_wa(1, :op2op1)
  end

  it "doesn't find without any poly has_one through poly has_one" do
    s0
    assert_wa(0, :op2op1)
  end

  it "doesn't find with a non matching poly has_one through poly has_one" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op1.create_bad_assocs!(:op2, :S0_op2op1, :S1_op2)

    assert_wa(0, :op2op1)
  end

  it "finds a matching poly has_one through poly has_one using an array for the association" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op1.create_assoc!(:op2, :S1_op2)
    op1.create_assoc!(:op2, :S1_op2)

    assert_wa(1, [:op1, :op2])
  end

  it "doesn't find without any poly has_one through poly has_one using an array for the association" do
    s0
    assert_wa(0, [:op1, :op2])
  end

  it "doesn't find with a non matching poly has_one through poly has_one using an array for the association" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op1.create_bad_assocs!(:op2, :S1_op2)

    assert_wa(0, [:op1, :op2])
  end

  it "finds a matching poly has_one through poly has_one through poly has_one" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op2 = op1.create_assoc!(:op2, :S0_op2op1, :S1_op2)
    op2.create_assoc!(:op3, :S0_op3op2op1, :S2_op3)
    op2.create_assoc!(:op3, :S0_op3op2op1, :S2_op3)

    assert_wa(1, :op3op2op1)
  end

  it "doesn't find without any poly has_one through poly has_one through poly has_one" do
    s0
    assert_wa(0, :op3op2op1)
  end

  it "doesn't find with a non matching poly has_one through poly has_one through poly has_one" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op2 = op1.create_assoc!(:op2, :S0_op2op1, :S1_op2)
    op2.create_bad_assocs!(:op3, :S0_op3op2op1, :S2_op3)

    assert_wa(0, :op3op2op1)
  end

  it "finds a matching poly has_one through a poly has_one with a source that is a poly has_one through" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op2 = op1.create_assoc!(:op2, :S1_op2)
    op2.create_assoc!(:op3, :S0_op3op1_op3op2, :S1_op3op2, :S2_op3)
    op2.create_assoc!(:op3, :S0_op3op1_op3op2, :S1_op3op2, :S2_op3)

    assert_wa(1, :op3op1_op3op2)
  end

  it "doesn't find without any poly has_one through a poly has_one with a source that is a poly has_one through" do
    s0
    assert_wa(0, :op3op1_op3op2)
  end

  it "doesn't find with a non matching poly has_one through a poly has_one with a source that is a poly has_one through" do
    op1 = s0.create_assoc!(:op1, :S0_op1)
    op2 = op1.create_assoc!(:op2, :S1_op2)
    op2.create_bad_assocs!(:op3, :S0_op3op1_op3op2, :S1_op3op2, :S2_op3)

    assert_wa(0, :op3op1_op3op2)
  end
end
