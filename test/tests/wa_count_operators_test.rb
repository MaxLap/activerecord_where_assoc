# frozen_string_literal: true

require_relative "../test_helper"

describe "wa_count" do
  let(:s0) { S0.create_default! }

  it "counts every matching has_many with every operators" do
    s0
    assert_wa_count_full(0, :m1)

    s0.create_assoc!(:m1, :S0_m1)
    assert_wa_count_full(1, :m1)

    s0.create_assoc!(:m1, :S0_m1)
    assert_wa_count_full(2, :m1)
  end

  it "counts every matching has_and_belongs_to_many with every operators" do
    s0
    assert_wa_count_full(0, :z1)

    s0.create_assoc!(:z1, :S0_z1)
    assert_wa_count_full(1, :z1)

    s0.create_assoc!(:z1, :S0_z1)
    assert_wa_count_full(2, :z1)
  end

  it "counts matching has_one as at most 1 with every operators" do
    skip if Test::SelectedDBHelper == Test::MySQL

    s0
    assert_wa_count_full(0, :o1)

    s0.create_assoc!(:o1, :S0_o1)
    assert_wa_count_full(1, :o1)

    s0.create_assoc!(:o1, :S0_o1)
    assert_wa_count_full(1, :o1)
  end

  it "counts matching belongs_to as at most 1 with every operators" do
    s0
    assert_wa_count_full(0, :b1)

    s0.create_assoc!(:b1, :S0_b1)
    assert_wa_count_full(1, :b1)

    s0.create_assoc!(:b1, :S0_b1)
    assert_wa_count_full(1, :b1)
  end
end
