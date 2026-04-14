# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "has_many's extensions are available" do
    s0_1 = s0
    s0_1.create_assoc!(:m1, :S0_m1)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:m1, :S0_m1)

    s0_4 = S0.create_default!
    s0_4.create_assoc!(:m1, :S0_m1, attributes: {extension_filter: true})

    assert_equal [s0_1, s0_3, s0_4], S0.where_assoc_count(1, :==, :m1).to_a.sort_by(&:id)
    assert_equal [s0_4], S0.where_assoc_count(1, :==, :m1, &:with_extension_filter).to_a.sort_by(&:id)
    assert_equal [s0_4], S0.where_assoc_exists(:m1, &:with_extension_filter).to_a.sort_by(&:id)
  end

  it "has_many :through's extensions are available" do
    s0_1 = s0
    s0_1.create_assoc!(:m1, :S0_m1).create_assoc!(:m2, :S0_m2m1, :S1_m2)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:m1, :S0_m1)

    s0_4 = S0.create_default!
    s0_4.create_assoc!(:m1, :S0_m1).create_assoc!(:m2, :S0_m2m1, :S1_m2, attributes: {extension_filter: true})

    assert_equal [s0_1, s0_4], S0.where_assoc_count(1, :==, :m2m1).to_a.sort_by(&:id)
    assert_equal [s0_4], S0.where_assoc_count(1, :==, :m2m1, &:with_extension_filter).to_a.sort_by(&:id)
    assert_equal [s0_4], S0.where_assoc_exists(:m2m1, &:with_extension_filter).to_a.sort_by(&:id)
  end

  it "has_and_belongs_to_many's extensions are available" do
    s0_1 = s0
    s0_1.create_assoc!(:z1, :S0_z1)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:z1, :S0_z1)

    s0_4 = S0.create_default!
    s0_4.create_assoc!(:z1, :S0_z1, attributes: {extension_filter: true})

    assert_equal [s0_1, s0_3, s0_4], S0.where_assoc_count(1, :==, :z1).to_a.sort_by(&:id)
    assert_equal [s0_4], S0.where_assoc_count(1, :==, :z1, &:with_extension_filter).to_a.sort_by(&:id)
    assert_equal [s0_4], S0.where_assoc_exists(:z1, &:with_extension_filter).to_a.sort_by(&:id)
  end
end
