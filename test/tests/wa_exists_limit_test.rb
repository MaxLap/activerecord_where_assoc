# frozen_string_literal: true

require "test_helper"

describe "wa_exists" do
  let(:s0) { S0.create_default! }

  it "has_many with #limit(0) never matches" do
    s0.create_assoc!(:m1, :S0_m1)
    assert_exists_with_matching(:m1)
    assert_exists_without_matching(:m1) { |s| s.limit(0) }
  end

  it "has_one with #limit(0) never matches" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0.create_assoc!(:o1, :S0_o1)
    assert_exists_with_matching(:o1)
    assert_exists_without_matching(:o1) { |s| s.limit(0) }
  end

  it "belongs_to with #limit(0) never matches" do
    s0.create_assoc!(:b1, :S0_b1)

    assert_exists_with_matching(:b1)
    assert_exists_without_matching(:b1) { |s| s.limit(0) }
  end

  it "has_and_belongs_to_many with #limit(0) never matches" do
    s0.create_assoc!(:z1, :S0_z1)

    assert_exists_with_matching(:z1)
    assert_exists_without_matching(:z1) { |s| s.limit(0) }
  end
end
