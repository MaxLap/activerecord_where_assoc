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

  it "raises an expection for invalid options" do
    assert_raises(ArgumentError) do
      S0.where_assoc_exists(:m1, nil, here_comes_a_bad_option: true).exists?
    end
  end
end
