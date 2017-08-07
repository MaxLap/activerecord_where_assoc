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
end
