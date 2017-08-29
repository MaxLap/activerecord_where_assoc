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

  it "_exists raises MySQLIsTerribleError for has_one with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLIsTerribleError) do
      S0.where_assoc_exists(:o1)
    end
  end

  # Classes for the following tests only
  class LimThroughS0 < ActiveRecord::Base
    self.table_name = "s0s"
    has_many :m1, class_name: "LimThroughS1", foreign_key: "s0_id"
    has_many :limited_m2m1, -> { limit(2).reorder("s2s.id desc") }, class_name: "LimThroughS2", through: :m1, source: :m2
  end

  class LimThroughS1 < ActiveRecord::Base
    self.table_name = "s1s"
    has_many :m2, class_name: "LimThroughS2", foreign_key: "s1_id"
  end

  class LimThroughS2 < ActiveRecord::Base
    self.table_name = "s2s"
  end

  it "_count raises LimitFromThroughScopeError for has_many :through with a limit" do
    assert_raises(ActiveRecordWhereAssoc::LimitFromThroughScopeError) do
      LimThroughS0.where_assoc_count(1, :<, :limited_m2m1)
    end
  end

  it "_exists raises LimitFromThroughScopeError for has_many :through with a limit" do
    assert_raises(ActiveRecordWhereAssoc::LimitFromThroughScopeError) do
      LimThroughS0.where_assoc_exists(:limited_m2m1)
    end
  end


  # Classes for the following tests only
  class OffThroughS0 < ActiveRecord::Base
    self.table_name = "s0s"
    has_many :m1, class_name: "OffThroughS1", foreign_key: "s0_id"
    has_many :offset_m2m1, -> { offset(2).reorder("s2s.id desc") }, class_name: "OffThroughS2", through: :m1, source: :m2
  end

  class OffThroughS1 < ActiveRecord::Base
    self.table_name = "s1s"
    has_many :m2, class_name: "OffThroughS2", foreign_key: "s1_id"
  end

  class OffThroughS2 < ActiveRecord::Base
    self.table_name = "s2s"
  end

  it "_count raises OffsetFromThroughScopeError for has_many :through with an offset" do
    assert_raises(ActiveRecordWhereAssoc::OffsetFromThroughScopeError) do
      OffThroughS0.where_assoc_count(1, :<, :offset_m2m1)
    end
  end

  it "_exists raises OffsetFromThroughScopeError for has_many :through with an offset" do
    assert_raises(ActiveRecordWhereAssoc::OffsetFromThroughScopeError) do
      OffThroughS0.where_assoc_exists(:offset_m2m1)
    end
  end
end
