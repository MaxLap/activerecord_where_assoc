# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  next if ActiveRecord.gem_version < Gem::Version.new("7.2")

  it "belongs_to with composite_key works" do
    ck1 = Ck1.create_default!(an_id1: 0, a_str1: "hi")
    ck1.create_assoc!(:b0, :Ck1_b0, attributes: {an_id0: 1, a_str0: "bar"})
    ck0_spam = ck1.create_assoc!(:b0, :Ck1_b0, attributes: {an_id0: 1, a_str0: "spam"})
    ck1.save! # Save the updates ids

    assert_wa_from(Ck1, 1, :b0)

    ck1_1 = Ck1.create_default!(an_id1: 1, a_str1: "foo")
    ck1_2 = Ck1.create_default!(an_id1: 12, a_str1: "foo")

    assert_equal [ck1], Ck1.where_assoc_count(1, :==, :b0).to_a.sort_by(&:an_id1)
    assert_equal [ck1_1, ck1_2], Ck1.where_assoc_count(0, :==, :b0).to_a.sort_by(&:an_id1)
  end

  it "has_many with composite_key works" do
    ck0 = Ck0.create_default!(an_id0: 1, a_str0: "foo")
    ck0.create_assoc!(:m1, :Ck0_m1, attributes: {an_id1: 1, a_str1: "bar"})
    ck0.create_assoc!(:m1, :Ck0_m1, attributes: {an_id1: 1, a_str1: "spam"})
    ck0.create_assoc!(:m1, :Ck0_m1, attributes: {an_id1: 2, a_str1: "bar"})

    Ck1.create_default!(an_id1: 42, a_str1: "foo")

    assert_wa_from(Ck0, 3, :m1)
  end

  it "has_one with composite_key works" do
    skip if Test::SelectedDBHelper == Test::MySQL

    ck0 = Ck0.create_default!(an_id0: 1, a_str0: "foo")
    ck0.create_assoc!(:o1, :Ck0_o1, attributes: {an_id1: 1, a_str1: "bar"})
    ck0.create_assoc!(:o1, :Ck0_o1, attributes: {an_id1: 1, a_str1: "spam"})
    ck0.create_assoc!(:o1, :Ck0_o1, attributes: {an_id1: 2, a_str1: "bar"})

    assert_wa_from(Ck0, 1, :o1)
  end

  # I don't think has_and_belongs_to_many supports composite keys?
  # it "has_and_belongs_to_many with composite_key works" do
  #   ck0 = Ck0.create_default!(an_id0: 1, a_str0: "foo")
  #   ck0.create_assoc!(:z1, :Ck0_z1, attributes: {an_id1: 1, a_str1: "bar"})
  #   ck0.create_assoc!(:z1, :Ck0_z1, attributes: {an_id1: 1, a_str1: "spam"})
  #   ck0.create_assoc!(:z1, :Ck0_z1, attributes: {an_id1: 2, a_str1: "bar"})

  #   assert_wa_from(Ck0, 3, :z1)
  # end


  it "has_many through has_many with composite_key works" do
    ck0 = Ck0.create_default!(an_id0: 1, a_str0: "foo")
    ck0.create_assoc!(:m1, :Ck0_m1, attributes: {an_id1: 1, a_str1: "bar"})
    ck1_2 = ck0.create_assoc!(:m1, :Ck0_m1, attributes: {an_id1: 1, a_str1: "spam"})
    ck0.create_assoc!(:m1, :Ck0_m1, attributes: {an_id1: 2, a_str1: "bar"})

    assert_wa_from(Ck0, 0, :m2m1)

    ck1_2.create_assoc!(:m2, :Ck1_m2, :Ck0_m2m1, attributes: {an_id2: 130, a_str2: "hello"})
    assert_wa_from(Ck0, 1, :m2m1)
  end

  it "raise on composite_key with never_alias_limit" do
    skip if Test::SelectedDBHelper == Test::MySQL

    sql = Ck0.where_assoc_exists(:o1) { from("hello") }.to_sql
    assert !sql.include?("an_int0")

    assert_raises(ActiveRecordWhereAssoc::NeverAliasLimitDoesntWorkWithCompositePrimaryKeysError) {
      Ck0.where_assoc_exists(:o1, nil, never_alias_limit: true) { from("hello") }.to_sql
    }
  end
end
