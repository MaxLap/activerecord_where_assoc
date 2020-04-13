# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "handles NullRelation in block on has_many" do
    s0
    assert_wa(0, :m1)
    assert_wa(0, :m1) { |scope| scope.none }

    s0.create_assoc!(:m1, :S0_m1)

    assert_wa(1, :m1)
    assert_wa(0, :m1) { |scope| scope.none }
  end

  it "handles NullRelation as condition on has_many association" do
    s0
    assert_wa(0, :m1_none)

    s0.create_assoc!(:m1, :S0_m1_none)

    assert_wa(0, :m1_none)

    # Just double checking that the create_assoc actually did something
    expected_m1_none_value = S1.test_condition_value_for(:default_scope) * S0.test_condition_value_for(:m1_none)
    assert S1.unscoped.where(s1s_column: expected_m1_none_value).exists?
  end

  it "handles NullRelation in block on has_one" do
    # MySQL doesn't support has_one
    next if Test::SelectedDBHelper == Test::MySQL

    s0
    assert_wa(0, :o1)
    assert_wa(0, :o1) { |scope| scope.none }

    s0.create_assoc!(:o1, :S0_o1)

    assert_wa(1, :o1)
    assert_wa(0, :o1) { |scope| scope.none }
  end

  it "handles NullRelation as condition on has_one association" do
    # MySQL doesn't support has_one
    next if Test::SelectedDBHelper == Test::MySQL

    s0
    assert_wa(0, :o1_none)

    s0.create_assoc!(:o1, :S0_o1_none)

    assert_wa(0, :o1_none)

    # Just double checking that the create_assoc actually did something
    expected_m1_none_value = S1.test_condition_value_for(:default_scope) * S0.test_condition_value_for(:o1_none)
    assert S1.unscoped.where(s1s_column: expected_m1_none_value).exists?
  end

  it "handles NullRelation in block on belongs_to" do
    s0
    assert_wa(0, :b1)
    assert_wa(0, :b1) { |scope| scope.none }

    s0.create_assoc!(:b1, :S0_b1)

    assert_wa(1, :b1)
    assert_wa(0, :b1) { |scope| scope.none }
  end

  it "handles NullRelation as condition on belongs_to association" do
    s0
    assert_wa(0, :b1_none)

    s0.create_assoc!(:b1, :S0_b1_none)

    assert_wa(0, :b1_none)

    # Just double checking that the create_assoc actually did something
    expected_m1_none_value = S1.test_condition_value_for(:default_scope) * S0.test_condition_value_for(:b1_none)
    assert S1.unscoped.where(s1s_column: expected_m1_none_value).exists?
  end

  it "handles NullRelation in block on has_and_belongs_to_many" do
    s0
    assert_wa(0, :z1)
    assert_wa(0, :z1) { |scope| scope.none }

    s0.create_assoc!(:z1, :S0_z1)

    assert_wa(1, :z1)
    assert_wa(0, :z1) { |scope| scope.none }
  end

  it "handles NullRelation as condition on has_and_belongs_to_many association" do
    s0
    assert_wa(0, :z1_none)

    s0.create_assoc!(:z1, :S0_z1_none)

    assert_wa(0, :z1_none)

    # Just double checking that the create_assoc actually did something
    expected_m1_none_value = S1.test_condition_value_for(:default_scope) * S0.test_condition_value_for(:z1_none)
    assert S1.unscoped.where(s1s_column: expected_m1_none_value).exists?
  end

  # ProfilePicture.where_assoc_exists(:profile, nil, poly_belongs_to: { PersonProfile => proc { |scope| scope.none } })
  it "handles NullRelation in poly_belongs_to" do
    s0

    assert_wa(0, :bp1, nil, poly_belongs_to: { S1 => proc { |scope| scope.none } })
    assert_wa(0, :bp1, nil, poly_belongs_to: [S1])

    s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    assert_wa(1, :bp1, nil, poly_belongs_to: [S1])
    without_manual_wa_test do
      assert_wa(0, :bp1, nil, poly_belongs_to: { S1 => proc { |scope| scope.none } })
    end
  end

end
