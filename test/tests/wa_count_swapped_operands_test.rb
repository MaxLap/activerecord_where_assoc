# frozen_string_literal: true

require_relative "../test_helper"

describe "wa_count" do
  let(:s0) { S0.create_default! }

  it "Properly reverses the operands and operators when a number is used as 3rd argument" do
    s0
    assert !S0.where_assoc_count(:m1, :==, 1).exists?
    assert !S0.where_assoc_count(:m1, "=", 1).exists?
    assert S0.where_assoc_count(:m1, :!=, 1).exists?
    assert S0.where_assoc_count(:m1, "<>", 1).exists?
    assert S0.where_assoc_count(:m1, :==, 0).exists?
    assert S0.where_assoc_count(:m1, "=", 0).exists?
    assert !S0.where_assoc_count(:m1, :!=, 0).exists?
    assert !S0.where_assoc_count(:m1, "<>", 0).exists?

    assert !S0.where_assoc_count(:m1, :>, 0).exists?
    assert S0.where_assoc_count(:m1, :>=, 0).exists?
    assert S0.where_assoc_count(:m1, :<, 1).exists?
    assert S0.where_assoc_count(:m1, :<=, 1).exists?

    s0.create_assoc!(:m1, :S0_m1)

    assert S0.where_assoc_count(:m1, :==, 1).exists?
    assert S0.where_assoc_count(:m1, "=", 1).exists?
    assert !S0.where_assoc_count(:m1, :!=, 1).exists?
    assert !S0.where_assoc_count(:m1, "<>", 1).exists?
    assert !S0.where_assoc_count(:m1, :==, 0).exists?
    assert !S0.where_assoc_count(:m1, "=", 0).exists?
    assert S0.where_assoc_count(:m1, :!=, 0).exists?
    assert S0.where_assoc_count(:m1, "<>", 0).exists?

    assert S0.where_assoc_count(:m1, :>, 0).exists?
    assert S0.where_assoc_count(:m1, :>=, 0).exists?
    assert !S0.where_assoc_count(:m1, :<, 1).exists?
    assert S0.where_assoc_count(:m1, :<=, 1).exists?

    s0.create_assoc!(:m1, :S0_m1)

    assert !S0.where_assoc_count(:m1, :==, 1).exists?
    assert !S0.where_assoc_count(:m1, "=", 1).exists?
    assert S0.where_assoc_count(:m1, :!=, 1).exists?
    assert S0.where_assoc_count(:m1, "<>", 1).exists?
    assert !S0.where_assoc_count(:m1, :==, 0).exists?
    assert !S0.where_assoc_count(:m1, "=", 0).exists?
    assert S0.where_assoc_count(:m1, :!=, 0).exists?
    assert S0.where_assoc_count(:m1, "<>", 0).exists?

    assert S0.where_assoc_count(:m1, :>, 0).exists?
    assert S0.where_assoc_count(:m1, :>=, 0).exists?
    assert !S0.where_assoc_count(:m1, :<, 1).exists?
    assert !S0.where_assoc_count(:m1, :<=, 1).exists?
  end

  it "Properly reverses the operands when a range is used as 3rd argument" do
    s0
    assert !S0.where_assoc_count(:m1, :==, 1..10).exists?
    assert !S0.where_assoc_count(:m1, "=", 1..10).exists?
    assert S0.where_assoc_count(:m1, :!=, 1..10).exists?
    assert S0.where_assoc_count(:m1, "<>", 1..10).exists?
    assert S0.where_assoc_count(:m1, :==, 0..10).exists?
    assert S0.where_assoc_count(:m1, "=", 0..10).exists?
    assert !S0.where_assoc_count(:m1, :!=, 0..10).exists?
    assert !S0.where_assoc_count(:m1, "<>", 0..10).exists?

    s0.create_assoc!(:m1, :S0_m1)

    assert S0.where_assoc_count(:m1, :==, 1..10).exists?
    assert S0.where_assoc_count(:m1, "=", 1..10).exists?
    assert !S0.where_assoc_count(:m1, :!=, 1..10).exists?
    assert !S0.where_assoc_count(:m1, "<>", 1..10).exists?
    assert S0.where_assoc_count(:m1, :==, 0..10).exists?
    assert S0.where_assoc_count(:m1, "=", 0..10).exists?
    assert !S0.where_assoc_count(:m1, :!=, 0..10).exists?
    assert !S0.where_assoc_count(:m1, "<>", 0..10).exists?

    10.times { s0.create_assoc!(:m1, :S0_m1) }

    assert !S0.where_assoc_count(:m1, :==, 1..10).exists?
    assert !S0.where_assoc_count(:m1, "=", 1..10).exists?
    assert S0.where_assoc_count(:m1, :!=, 1..10).exists?
    assert S0.where_assoc_count(:m1, "<>", 1..10).exists?
    assert !S0.where_assoc_count(:m1, :==, 0..10).exists?
    assert !S0.where_assoc_count(:m1, "=", 0..10).exists?
    assert S0.where_assoc_count(:m1, :!=, 0..10).exists?
    assert S0.where_assoc_count(:m1, "<>", 0..10).exists?
  end
end
