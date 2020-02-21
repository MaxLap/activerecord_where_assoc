# frozen_string_literal: true

require_relative "../test_helper"

# rubocop:disable Metrics/LineLength
describe "SQL methods" do
  it "#assoc_exists_sql generates expected sql" do
    sql = S0.assoc_exists_sql(:m1)
    expected_sql = %(EXISTS (SELECT 1 FROM "s1s" WHERE ("s1s"."s1s_column" % __NUMBER__ = 0) AND ("s1s"."s1s_column" % __NUMBER__ = 0) AND "s1s"."s0_id" = "s0s"."id"))
    expected_sql_regex = Regexp.new(Regexp.quote(expected_sql).gsub("__NUMBER__", '\d+').gsub('"', '["`]?'))
    assert_match expected_sql_regex, sql.gsub(/\s+/, ' ')
  end

  it "#assoc_not_exists_sql generates expected sql" do
    sql = S0.assoc_not_exists_sql(:m1)
    expected_sql = %(NOT EXISTS (SELECT 1 FROM "s1s" WHERE ("s1s"."s1s_column" % __NUMBER__ = 0) AND ("s1s"."s1s_column" % __NUMBER__ = 0) AND "s1s"."s0_id" = "s0s"."id"))
    expected_sql_regex = Regexp.new(Regexp.quote(expected_sql).gsub("__NUMBER__", '\d+').gsub('"', '["`]?'))
    assert_match expected_sql_regex, sql.gsub(/\s+/, ' ')
  end

  it "#only_assoc_count_sql generates expected sql" do
    sql = S0.only_assoc_count_sql(:m1)
    expected_sql = %(COALESCE((SELECT COUNT(*) FROM "s1s" WHERE ("s1s"."s1s_column" % __NUMBER__ = 0) AND ("s1s"."s1s_column" % __NUMBER__ = 0) AND "s1s"."s0_id" = "s0s"."id"), 0))
    expected_sql_regex = Regexp.new(Regexp.quote(expected_sql).gsub("__NUMBER__", '\d+').gsub('"', '["`]?'))
    assert_match expected_sql_regex, sql.gsub(/\s+/, ' ')
  end

  it "#compare_assoc_count_sql generates expected sql" do
    sql = S0.compare_assoc_count_sql(5, :<, :m1)
    expected_sql = %((5) < COALESCE((SELECT COUNT(*) FROM "s1s" WHERE ("s1s"."s1s_column" % __NUMBER__ = 0) AND ("s1s"."s1s_column" % __NUMBER__ = 0) AND "s1s"."s0_id" = "s0s"."id"), 0))
    expected_sql_regex = Regexp.new(Regexp.quote(expected_sql).gsub("__NUMBER__", '\d+').gsub('"', '["`]?'))
    assert_match expected_sql_regex, sql.gsub(/\s+/, ' ')
  end
end
