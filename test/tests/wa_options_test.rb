# frozen_string_literal: true

require "test_helper"

describe "wa" do
  it "doesn't use #from when options[:never_alias_limit]" do
    skip if Test::SelectedDBHelper == Test::MySQL

    sql = LimOffOrdS0.where_assoc_exists(:m1) { from("hello") }.to_sql
    assert !sql.include?("id")

    sql = LimOffOrdS0.where_assoc_exists(:m1, nil, never_alias_limit: true) { from("hello") }.to_sql
    assert sql.include?("id")

    with_wa_default_options(never_alias_limit: true) do
      sql = LimOffOrdS0.where_assoc_exists(:m1) { from("hello") }.to_sql
      assert sql.include?("id")
    end
  end
end
