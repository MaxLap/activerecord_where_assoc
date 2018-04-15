# frozen_string_literal: true

require_relative "../test_helper"

describe "wa_count" do
  let(:s0) { S0.create_default! }

  it "compare to a column using a string on left_side with has_many" do
    s0.update_attributes(s0s_adhoc_column: 2)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.create_assoc!(:m1, :S0_m1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.create_assoc!(:m1, :S0_m1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.create_assoc!(:m1, :S0_m1)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?

    s0.update_attributes(s0s_adhoc_column: 3)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :m1).exists?
  end

  it "compare to a column using a string on left_side with has_and_belongs_to_many" do
    s0.update_attributes(s0s_adhoc_column: 2)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.create_assoc!(:z1, :S0_z1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.create_assoc!(:z1, :S0_z1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.create_assoc!(:z1, :S0_z1)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?

    s0.update_attributes(s0s_adhoc_column: 3)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :<, :z1).exists?
  end

  it "compare to a column using a string on left_side with has_one" do
    skip if Test::SelectedDBHelper == Test::MySQL

    s0.update_attributes(s0s_adhoc_column: 0)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?

    o1 = s0.create_assoc!(:o1, :S0_o1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?

    o1.destroy
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?

    s0.update_attributes(s0s_adhoc_column: 1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :o1).exists?
  end

  it "compare to a column using a string on left_side with belongs_to" do
    s0.update_attributes(s0s_adhoc_column: 0)
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?

    b1 = s0.create_assoc!(:b1, :S0_b1)
    s0.save!
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?

    b1.destroy
    assert S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?

    s0.update_attributes(s0s_adhoc_column: 1)
    assert !S0.where_assoc_count("s0s.s0s_adhoc_column", :==, :b1).exists?
  end
end
