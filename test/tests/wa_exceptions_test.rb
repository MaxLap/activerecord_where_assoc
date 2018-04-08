# frozen_string_literal: true

require "test_helper"

describe "wa" do
  let(:s0) { SchemaS0.create! }

  it "_exists raises ActiveRecord::AssociationNotFoundError if missing association" do
    assert_raises(ActiveRecord::AssociationNotFoundError) do
      S0.where_assoc_exists(:this_doesnt_exist)
    end
  end

  it "_count raises ActiveRecord::AssociationNotFoundError if missing association" do
    assert_raises(ActiveRecord::AssociationNotFoundError) do
      S0.where_assoc_count(1, :<, :this_doesnt_exist)
    end
  end

  it "_exists raises MySQLIsTerribleError for has_one with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLIsTerribleError) do
      S0.where_assoc_exists(:o1)
    end
  end

  it "_count raises MySQLIsTerribleError for has_one with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLIsTerribleError) do
      S0.where_assoc_count(1, :<, :o1)
    end
  end

  it "_exists raises NotImplementedError for polymorphic belongs_to" do
    assert_raises(NotImplementedError) do
      S0.where_assoc_exists(:bp1)
    end
  end

  it "_count raises NotImplementedError for polymorphic belongs_to" do
    assert_raises(NotImplementedError) do
      S0.where_assoc_count(1, :<, :bp1)
    end
  end
end
