# frozen_string_literal: true

require "test_helper"

describe "wa" do
  let(:s0) { SchemaS0.create! }

  it "belongs_to works with table_names that have a schema" do
    s0.create_b1!
    s0.save! # Save the changed id

    assert_wa_from(SchemaS0, 1, :b1)
  end

  it "has_one works with table_names that have a schema" do
    skip if Test::SelectedDBHelper == Test::MySQL

    s0.create_has_one!(:o1)

    assert_wa_from(SchemaS0, 1, :o1)
  end

  it "has_many works with table_names that have a schema" do
    s0.m1.create!

    assert_wa_from(SchemaS0, 1, :m1)
  end

  it "has_and_belongs_to_many works with table_names that have a schema" do
    s0.z1.create!

    assert_wa_from(SchemaS0, 1, :z1)
  end
end
