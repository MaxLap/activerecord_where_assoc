# frozen_string_literal: true

require_relative "../../test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  def check_association(association, &block)
    # With nothing at all
    assert !S0.where_assoc_count(1, :==, association).exists?, caller(0)
    assert !S0.where_assoc_count(1, :!=, association).exists?
    assert !S0.where_assoc_exists(association).exists?
    assert !S0.where_assoc_not_exists(association).exists?

    # With a record of the association
    assoc_record = S1.create_default!("S0_#{association}")
    assert !S0.where_assoc_count(1, :==, association).exists?
    assert !S0.where_assoc_count(1, :!=, association).exists?
    assert !S0.where_assoc_exists(association).exists?
    assert !S0.where_assoc_not_exists(association).exists?

    # Also with a non-matching record in the source model
    s0
    assert_wa(0, association)

    # The block is to make sure that th scoping is done correctly. It must fix things up so
    # that there is now a match
    yield assoc_record

    assert_wa(1, association)
  rescue Minitest::Assertion
    # Adding more of the backtrace to the message to make it easier to know where things failed.
    raise $!, "#{$!}\n#{Minitest.filter_backtrace($!.backtrace).join("\n")}", $!.backtrace
  end

  it "always returns no result for belongs_to if no possible ones exists" do
    check_association(:b1) do |b1|
      s0.update!(s1_id: b1.id)
    end
  end

  it "always returns no result for has_and_belongs_to_many if no possible ones exists" do
    check_association(:z1) do |z1|
      s0.z1 << z1
    end
  end

  it "always returns no result for has_many if no possible ones exists" do
    check_association(:m1) do |m1|
      m1.update!(s0_id: s0.id)
    end
  end

  it "always returns no result for has_one if no possible ones exists" do
    skip if Test::SelectedDBHelper == Test::MySQL
    check_association(:o1) do |o1|
      o1.update!(s0_id: s0.id)
    end
  end

  it "always returns no result for polymorphic has_many if no possible ones exists" do
    check_association(:mp1) do |mp1|
      mp1.update!(has_s1s_poly_id: s0.id, has_s1s_poly_type: "S0")
    end
  end
end
