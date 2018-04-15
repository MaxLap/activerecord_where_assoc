# frozen_string_literal: true

require_relative "../test_helper"

# Has_one associations should behave similarly to a belongs_to in that only
# one record should be tested: the one that would be returned by using the
# association on a record. This is the only record that must match (or
# not match) the condition given to the where_assoc_* methods.
#
# All the has_one associations have a order('id DESC') for the tests, so a
# record created later must shadow earlier ones, as long as it matches the
# scopes on the associations and the default_scope of the record.

describe "wa has_one" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  let(:s0) { S0.create_default! }

  it "only check against the last associated record" do
    s0.create_assoc!(:o1, :S0_o1, adhoc_value: 1)
    assert_wa(1, :o1, S1.adhoc_column_name => 1)

    s0.create_assoc!(:o1, :S0_o1) # Shadows the one with an adhoc_value
    assert_wa(0, :o1, S1.adhoc_column_name => 1)
  end

  it "only check against the last associated record when using a through association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S0_o2o1, :S1_o2, adhoc_value: 1)
    assert_wa(1, :o2o1, S2.adhoc_column_name => 1)

    o1.create_assoc!(:o2, :S0_o2o1, :S1_o2) # Shadows the final association that would match
    assert_wa(0, :o2o1, S2.adhoc_column_name => 1)
  end

  it "only check against the last associated record when using an array for the association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S1_o2, adhoc_value: 1)
    assert_wa(1, [:o1, :o2], S2.adhoc_column_name => 1)

    o1.create_assoc!(:o2, :S1_o2) # Shadows the final association that would match
    assert_wa(0, [:o1, :o2], S2.adhoc_column_name => 1)
  end

  it "only check against the last intermediary record when using a through association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S0_o2o1, :S1_o2)
    assert_wa(1, :o2o1)

    s0.create_assoc!(:o1, :S0_o1) # Shadows the intermediary association that would match
    without_manual_wa_test do # ActiveRecord checks every possible match of o1 instead of only the last one...
      assert_wa(0, :o2o1)
    end
  end

  it "only check against the last intermediary record when using an array for the association" do
    o1 = s0.create_assoc!(:o1, :S0_o1)
    o1.create_assoc!(:o2, :S1_o2)
    assert_wa(1, [:o1, :o2])

    s0.create_assoc!(:o1, :S0_o1) # Shadows the intermediary association that would match
    assert_wa(0, [:o1, :o2])
  end
end
