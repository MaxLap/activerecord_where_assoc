# frozen_string_literal: true

require_relative "../test_helper"

# has_one requires doing sub-queries with SELECT IN / applying limits to
# handle conditions / counts properly. However, when there is no conditions and no counts,
# the deepest layer can avoid those sub-queries, which is faster.
#
# Another optimization is that if there is a unique index on the column, then we can us
# the has_many path as long as there is no offset.

describe "wa_exists(has_one)" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  it "with a single has_one and no condition, doesn't do a sub-query" do
    sql = S0.where_assoc_exists(:o1).to_sql
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'
  end

  it "with a single has_one and a block, does a sub-query" do
    sql = S0.where_assoc_exists(:o1) {}.to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'
  end

  it "with a single has_one and a condition, does a sub-query" do
    sql = S0.where_assoc_exists(:o1, id: 1).to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'
  end


  it "with a two has_one and no condition, does a sub-query only once" do
    sql = S0.where_assoc_exists([:o1, :o2]).to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'

    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "s2s"'
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s2s".*'
  end

  it "with a two has_one and a block, does two sub-queries" do
    sql = S0.where_assoc_exists([:o1, :o2]) {}.to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'

    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s2s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s2s".*'
  end

  it "with a two has_one and a condition, does two sub-queries" do
    sql = S0.where_assoc_exists([:o1, :o2], id: 1).to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'

    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s2s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s2s".*'
  end


  it "with a has_one through has_one and no condition, does a sub-query only once" do
    sql = S0.where_assoc_exists(:o2o1).to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'

    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "s2s"'
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s2s".*'
  end

  it "with a has_one through has_one and a block, does two sub-queries" do
    sql = S0.where_assoc_exists(:o2o1) {}.to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'

    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s2s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s2s".*'
  end

  it "with a has_one through has_one and a condition, does two sub-queries" do
    sql = S0.where_assoc_exists(:o2o1, id: 1).to_sql
    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s1s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s1s".*'

    refute_includes sql.squeeze(" "), 'SELECT 1 FROM "s2s"'
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM (SELECT "s2s".*'
  end
end

describe "wa_exists(schema has_one)" do
  next if Test::SelectedDBHelper == Test::SQLite3
  next if Test::SelectedDBHelper == Test::MySQL

  it "with a single schema has_one and no condition, doesn't do a sub-query" do
    sql = S0.where_assoc_exists(:schema_o1).to_sql
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "bar_schema"."schema_s1s"'
    refute_includes sql.squeeze(" "), ' IN (SELECT "bar_schema"."schema_s1s"'
  end

  it "with a single schema has_one and a condition, does a ...IN..." do
    sql = S0.where_assoc_exists(:schema_o1, id: 1).to_sql
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "bar_schema"."schema_s1s"'
    assert_includes sql.squeeze(" "), ' IN (SELECT "bar_schema"."schema_s1s"'
  end


  it "with two single schema has_one and no condition, does a single sub-query with ...IN..." do
    sql = S0.where_assoc_exists([:schema_o1, :schema_o2]).to_sql
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "bar_schema"."schema_s1s"'
    assert_includes sql.squeeze(" "), ' IN (SELECT "bar_schema"."schema_s1s"'

    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "bar_schema"."schema_s2s"'
    refute_includes sql.squeeze(" "), ' IN (SELECT "bar_schema"."schema_s2s"'
  end

  it "with two single schema has_one and a condition, does two ...IN..." do
    sql = S0.where_assoc_exists([:schema_o1, :schema_o2], id: 1).to_sql
    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "bar_schema"."schema_s1s"'
    assert_includes sql.squeeze(" "), ' IN (SELECT "bar_schema"."schema_s1s"'

    assert_includes sql.squeeze(" "), 'SELECT 1 FROM "bar_schema"."schema_s2s"'
    assert_includes sql.squeeze(" "), ' IN (SELECT "bar_schema"."schema_s2s"'
  end
end

describe "wa_count(has_one)" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  it "with a single has_one, does a sub-query (because the count needs it)" do
    sql = S0.where_assoc_count(1, :<, :o1).to_sql
    assert_includes sql.squeeze(" "), 'SELECT COUNT(*) FROM (SELECT "s1s".*'
  end

  it "with a two has_one and a condition, does two sub-queries (because the count needs it)" do
    sql = S0.where_assoc_count(1, :<, [:o1, :o2]).to_sql
    assert_includes sql.squeeze(" "), 'FROM (SELECT "s1s".*'
    assert_includes sql.squeeze(" "), 'SELECT COUNT(*) FROM (SELECT "s2s".*'
  end

  it "with a a has_one through has_one and a condition, does two sub-queries (because the count needs it)" do
    sql = S0.where_assoc_count(1, :<, :o2o1).to_sql
    assert_includes sql.squeeze(" "), 'FROM (SELECT "s1s".*'
    assert_includes sql.squeeze(" "), 'SELECT COUNT(*) FROM (SELECT "s2s".*'
  end
end