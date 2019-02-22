# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

# Every table is a step. In tests, you always go toward the bigger step.
# You can do it using a belongs_to, or has_one/has_many.
# Try to make most columns unique so that any wrong column used is obvious in an error message.

ActiveRecord::Schema.define do
  create_table :s0s do |t|
    t.integer :s1_id

    t.integer :s0s_belongs_to_poly_id
    t.string :s0s_belongs_to_poly_type

    t.integer :s0s_column, limit: 8
    t.integer :s0s_adhoc_column, limit: 8
  end

  create_table :s1s do |t|
    t.integer :s0_id
    t.integer :s2_id

    t.integer :has_s1s_poly_id
    t.string :has_s1s_poly_type
    t.integer :s1s_belongs_to_poly_id
    t.string :s1s_belongs_to_poly_type

    t.integer :s1s_column, limit: 8
    t.integer :s1s_adhoc_column, limit: 8
  end

  create_table :s2s do |t|
    t.integer :s1_id
    t.integer :s3_id

    t.integer :has_s2s_poly_id
    t.string :has_s2s_poly_type
    t.integer :s2s_belongs_to_poly_id
    t.string :s2s_belongs_to_poly_type

    t.integer :s2s_column, limit: 8
    t.integer :s2s_adhoc_column, limit: 8
  end

  create_table :s3s do |t|
    t.integer :s2_id

    t.integer :has_s3s_poly_id
    t.string :has_s3s_poly_type

    t.integer :s3s_column, limit: 8
    t.integer :s3s_adhoc_column, limit: 8
  end

  create_join_table :s0s, :s1s
  create_join_table :s1s, :s2s
  create_join_table :s2s, :s3s

  if Test::SelectedDBHelper == Test::Postgres
    execute <<-SQL
      CREATE SCHEMA foo_schema;
    SQL

    execute <<-SQL
      CREATE SCHEMA bar_schema;
    SQL

    execute <<-SQL
      CREATE SCHEMA spam_schema;
    SQL
  elsif Test::SelectedDBHelper == Test::SQLite3
    # ATTACH DATABASE (the equivalent) is not supported by active record.
    # See https://github.com/rails/rails/pull/35339#issuecomment-466265426
  elsif Test::SelectedDBHelper == Test::MySQL
    execute <<-SQL
      CREATE DATABASE foo_schema;
    SQL

    execute <<-SQL
      CREATE DATABASE bar_schema;
    SQL

    execute <<-SQL
      CREATE DATABASE spam_schema;
    SQL
  end

  if Test::SelectedDBHelper != Test::SQLite3
    create_table "foo_schema.schema_s0s" do |t|
      t.integer :schema_s1_id
    end

    create_table "bar_schema.schema_s1s" do |t|
      t.integer :schema_s0_id
      t.integer :schema_s2_id
    end

    create_join_table "schema_s0s", "schema_s1s", table_name: "spam_schema.schema_s0s_schema_s1s"

    create_table "bar_schema.schema_s2s" do |t|
      t.integer :schema_s1_id
    end
  end

  create_table "sti_s0s" do |t|
    t.integer :sti_s1_id
    t.string :sti_s1_type
    t.string :type
  end

  create_table "sti_s1s" do |t|
    t.integer :sti_s0_id
    t.string :sti_s0_type
    t.string :type
  end

  create_join_table "sti_s0s", "sti_s1s", table_name: "sti_s0s_sti_s1s"

  create_table "lew_s0s" do |t|
    t.integer :lew_s1_id

    t.string :lew_s0s_column
  end

  create_table "lew_s1s" do |t|
    t.integer :lew_s0_id

    t.string :lew_s1s_column
  end

  create_join_table "lew_s0s", "lew_s1s", table_name: "lew_s0s_lew_s1s"

  create_table :recursive_s do |t|
    t.integer :recursive_s_column

    t.integer :belongs_id
    t.integer :belongs_type

    t.integer :has_id
    t.integer :has_type
  end
end
