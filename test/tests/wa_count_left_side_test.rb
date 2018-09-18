# frozen_string_literal: true

require_relative "../test_helper"

describe "wa_count" do
  let(:s0) { S0.create_default! }

  it "compare to a column using a string on left_side with has_many" do
    s0.update(s0s_adhoc_column: 2)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.create_assoc!(:m1, :S0_m1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.create_assoc!(:m1, :S0_m1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.create_assoc!(:m1, :S0_m1)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.update(s0s_adhoc_column: 3)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?
  end

  it "compare to a column using a string on left_side with has_and_belongs_to_many" do
    s0.update(s0s_adhoc_column: 2)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.create_assoc!(:z1, :S0_z1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.create_assoc!(:z1, :S0_z1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.create_assoc!(:z1, :S0_z1)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.update(s0s_adhoc_column: 3)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?
  end

  it "compare to a column using a string on left_side with has_one" do
    skip if Test::SelectedDBHelper == Test::MySQL

    s0.update(s0s_adhoc_column: 0)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?

    o1 = s0.create_assoc!(:o1, :S0_o1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?

    o1.destroy
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?

    s0.update(s0s_adhoc_column: 1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?
  end

  it "compare to a column using a string on left_side with belongs_to" do
    s0.update(s0s_adhoc_column: 0)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?

    b1 = s0.create_assoc!(:b1, :S0_b1)
    s0.save!
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?

    b1.destroy
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?

    s0.update(s0s_adhoc_column: 1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?
  end

  it "compare against a Range on left_side with has_many" do
    s0

    assert_assoc_count_in_range(0..10)
    assert_assoc_count_not_in_range(3..5)

    s0.create_assoc!(:m1, :S0_m1)
    assert_assoc_count_not_in_range(3..5)

    s0.create_assoc!(:m1, :S0_m1)
    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_in_range(3..5)

    s0.create_assoc!(:m1, :S0_m1)
    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_in_range(3..5)

    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_not_in_range(3..5)
  end

  it "compare against an exclusive Range on left_side with has_many" do
    s0
    assert_assoc_count_in_range(0...2)

    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_in_range(0...2)

    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_not_in_range(0...2)
  end

  it "compare against an exclusive float Range on left_side with has_many" do
    s0
    assert_assoc_count_in_range(-0.01...2.0)
    assert_assoc_count_in_range(0.0...1.99)
    assert_assoc_count_in_range(0.0...2.0)
    assert_assoc_count_in_range(0.0...2.01)
    assert_assoc_count_not_in_range(0.01...2.0)

    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_in_range(-0.01...2.0)
    assert_assoc_count_in_range(0.0...1.99)
    assert_assoc_count_in_range(0.0...2.0)
    assert_assoc_count_in_range(0.0...2.01)
    assert_assoc_count_in_range(0.01...2.0)

    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_not_in_range(-0.01...2.0)
    assert_assoc_count_not_in_range(0.0...1.99)
    assert_assoc_count_not_in_range(0.0...2.0)
    assert_assoc_count_in_range(0.0...2.01)
    assert_assoc_count_not_in_range(0.01...2.0)
  end

  infinite_range_right_values = [Float::INFINITY]
  infinite_range_right_values << nil if RUBY_VERSION >= "2.6.0" # Ruby 2.6's new `12..` syntax for infinite range puts a nil
  infinite_range_right_values.each do |infinite_range_value|
    it "compares against an infinite in Range's right side (#{infinite_range_value.inspect})" do
      s0

      assert_assoc_count_in_range(0..infinite_range_value)
      assert_assoc_count_in_range(0...infinite_range_value)
      assert_assoc_count_not_in_range(1..infinite_range_value)
      assert_assoc_count_not_in_range(1...infinite_range_value)

      s0.create_assoc!(:m1, :S0_m1)
      s0.create_assoc!(:m1, :S0_m1)

      assert_assoc_count_in_range(0..infinite_range_value)
      assert_assoc_count_in_range(0...infinite_range_value)
      assert_assoc_count_in_range(2..infinite_range_value)
      assert_assoc_count_in_range(2...infinite_range_value)
      assert_assoc_count_not_in_range(3..infinite_range_value)
      assert_assoc_count_not_in_range(3...infinite_range_value)
    end
  end

  it "compares against an infinite in Range's left side" do
    s0

    assert_assoc_count_not_in_range(-Float::INFINITY..-1)
    assert_assoc_count_not_in_range(-Float::INFINITY...0)
    assert_assoc_count_in_range(-Float::INFINITY..0)
    assert_assoc_count_in_range(-Float::INFINITY...1)

    s0.create_assoc!(:m1, :S0_m1)
    s0.create_assoc!(:m1, :S0_m1)

    assert_assoc_count_not_in_range(-Float::INFINITY..1)
    assert_assoc_count_not_in_range(-Float::INFINITY...2)
    assert_assoc_count_in_range(-Float::INFINITY..2)
    assert_assoc_count_in_range(-Float::INFINITY...3)
  end

  def assert_assoc_count_in_range(range)
    assert S0.where_assoc_count(range, :==, :m1).exists?, "(==) Should exist but doesn't"
    assert !S0.where_assoc_count(range, :!=, :m1).exists?, "(!=) Should not exist but does"
  end

  def assert_assoc_count_not_in_range(range)
    assert !S0.where_assoc_count(range, :==, :m1).exists?, "(==) Should not exist but does"
    assert S0.where_assoc_count(range, :!=, :m1).exists?, "(!=) Should exist but doesn't"
  end
end
