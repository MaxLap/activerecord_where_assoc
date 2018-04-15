# frozen_string_literal: true

require_relative "../test_helper"

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

  it "_count raises MySQLDoesntSupportSubLimitError for has_one with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLDoesntSupportSubLimitError) do
      S0.where_assoc_count(1, :<, :o1)
    end
  end

  it "_count doesn't raise MySQLDoesntSupportSubLimitError for has_one with MySQL if option[:ignore_limit]" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_nothing_raised do
      S0.where_assoc_count(1, :<, :o1, nil, ignore_limit: true)

      with_wa_default_options(ignore_limit: true) do
        S0.where_assoc_count(1, :<, :o1)
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

  it "_count raises MySQLDoesntSupportSubLimitError for has_many with limit with MySQL" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_raises(ActiveRecordWhereAssoc::MySQLDoesntSupportSubLimitError) do
      LimOffOrdS0.where_assoc_count(1, :<, :ml1)
    end
  end

  it "_count doesn't raise MySQLDoesntSupportSubLimitError for has_many with limit with MySQL  if option[:ignore_limit]" do
    skip if Test::SelectedDBHelper != Test::MySQL

    assert_nothing_raised do
      LimOffOrdS0.where_assoc_count(1, :<, :ml1, nil, ignore_limit: true)

      with_wa_default_options(ignore_limit: true) do
        LimOffOrdS0.where_assoc_count(1, :<, :ml1)
      end
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
