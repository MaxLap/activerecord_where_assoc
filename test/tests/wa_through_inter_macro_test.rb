# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  # MySQL doesn't support has_one
  next if Test::SelectedDBHelper == Test::MySQL

  let(:s0) { S0.create_default! }

  it "has_one through: belongs_to, source: belongs_to doesn't use LIMIT" do
    scope = S0.where_assoc_exists(:ob2b1)
    sql = scope.to_sql
    scope.to_a # Make sure it doesn't fail
    refute_includes sql.upcase, "LIMIT"
  end
end
