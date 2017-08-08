# frozen_string_literal: true

require "test_helper"

describe "wa_count has_one" do
  let(:s0) { S0.create_default! }

  it "matches with Arel condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1, S1.arel_table[S1.adhoc_column_name].eq(1))
    assert_wa_count(0, :o1, S1.arel_table[S1.adhoc_column_name].eq(2))
  end

  it "matches with Array-String condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1, ["#{S1.adhoc_column_name} = ?", 1])
    assert_wa_count(0, :o1, ["#{S1.adhoc_column_name} = ?", 2])
  end

  it "matches with a block condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1) { |s| s.where(S1.adhoc_column_name => 1) }
    assert_wa_count(0, :o1) { |s| s.where(S1.adhoc_column_name => 2) }
  end

  it "matches with a no arg block condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1) { where(S1.adhoc_column_name => 1) }
    assert_wa_count(0, :o1) { where(S1.adhoc_column_name => 2) }
  end

  it "matches with Hash condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1, S1.adhoc_column_name => 1)
    assert_wa_count(0, :o1, S1.adhoc_column_name => 2)
  end

  it "matches with String condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1, "#{S1.adhoc_column_name} = 1")
    assert_wa_count(0, :o1, "#{S1.adhoc_column_name} = 2")
  end

  it "matches with Symbol condition" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa_count(1, :o1, :adhoc_is_one)
    assert_wa_count(0, :o1, :adhoc_is_two)
  end
end
