# frozen_string_literal: true

require "test_helper"

describe "wa_count" do
  let(:s0) { SchemaS0.create! }

  it "belongs_to works with table_names that have a schema" do
    s0.create_b1!
    s0.save! # Save the changed id

    assert_wa_count_full_from(SchemaS0, 1, :b1)
  end

  it "has_one works with table_names that have a schema" do
    s0.create_o1!

    assert_wa_count_full_from(SchemaS0, 1, :o1)
  end

  it "has_many works with table_names that have a schema" do
    s0.m1.create!

    assert_wa_count_full_from(SchemaS0, 1, :m1)
  end
end
