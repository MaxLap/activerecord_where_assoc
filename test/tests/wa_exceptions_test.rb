# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  let(:s0) { S0.create! }

  it "_exists raises ActiveRecord::AssociationNotFoundError if missing association" do
    assert_raises(ActiveRecord::AssociationNotFoundError) do
      S0.where_assoc_exists(:this_doesnt_exist)
    end
  end

  it "_exists raises MySQLDoesntSupportSubLimitError for has_one with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLDoesntSupportSubLimitError) do
      S0.where_assoc_exists(:o1)
    end
  end

  it "_exists doesn't raise MySQLDoesntSupportSubLimitError for has_one with MySQL if option[:ignore_limit]" do
    skip if Test::SelectedDBHelper != Test::MySQL
    assert_nothing_raised do
      S0.where_assoc_exists(:o1, nil, ignore_limit: true)

      with_wa_default_options(ignore_limit: true) do
        S0.where_assoc_exists(:o1)
      end
    end
  end

  it "_exists raises MySQLDoesntSupportSubLimitError for has_many with limit with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLDoesntSupportSubLimitError) do
      LimOffOrdS0.where_assoc_exists(:ml1)
    end
  end

  it "_exists doesn't raise MySQLDoesntSupportSubLimitError for has_many with limit with MySQL  if option[:ignore_limit]" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_nothing_raised do
      LimOffOrdS0.where_assoc_exists(:ml1, nil, ignore_limit: true)

      with_wa_default_options(ignore_limit: true) do
        LimOffOrdS0.where_assoc_exists(:ml1)
      end
    end
  end

  it "_exists raises PolymorphicBelongsToWithoutClasses for polymorphic belongs_to without :poly_belongs_to option" do
    assert_raises(ActiveRecordWhereAssoc::PolymorphicBelongsToWithoutClasses) do
      S0.where_assoc_exists(:bp1)
    end
  end

  it "_exists raises PolymorphicBelongsToWithoutClasses for polymorphic belongs_to without :poly_belongs_to option" do
    assert_raises(ActiveRecordWhereAssoc::PolymorphicBelongsToWithoutClasses) do
      S0.where_assoc_exists(:mbp2mp1)
    end
  end

  it "_count refuses ranges with wrong operators" do
    %w(< > <= >=).each do |operator|
      exc = assert_raises(ArgumentError) do
        S0.where_assoc_count(0..10, operator, :m1)
      end

      assert_includes exc.message, operator
    end
  end

  it "_exists fails nicely if given a bad :poly_belongs_to" do
    assert_raises(ArgumentError) do
      S0.where_assoc_exists(:mbp2mp1, nil, poly_belongs_to: 123)
    end
    assert_raises(ArgumentError) do
      S0.where_assoc_exists(:mbp2mp1, nil, poly_belongs_to: [123])
    end
    assert_raises(ArgumentError) do
      # There is a different error message to try to be helpful if someone does that
      S0.where_assoc_exists(:mbp2mp1, nil, poly_belongs_to: [S0.new])
    end
  end

  it "_exists fails nicely if given a has_many :through a polymorphic belongs_to" do
    assert_raises(ActiveRecord::HasManyThroughAssociationPolymorphicThroughError) do
      S0.where_assoc_exists(:mp2bp1)
    end
  end

  it "_exists fails nicely if given a has_one :through a polymorphic belongs_to" do
    exc = if defined?(ActiveRecord::HasOneAssociationPolymorphicThroughError)
            ActiveRecord::HasOneAssociationPolymorphicThroughError
          else
            ActiveRecord::HasManyThroughAssociationPolymorphicThroughError
          end
    assert_raises(exc) do
      S0.where_assoc_exists(:op2bp1)
    end
  end
end
