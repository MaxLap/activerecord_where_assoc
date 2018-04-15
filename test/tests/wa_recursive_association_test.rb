# frozen_string_literal: true

require_relative "../test_helper"

# Since the goal is to check only against the records that would be returned by the association,
# we need to follow the expected behavior for limits, offset and order.

describe "wa" do
  def check_recursive_association(association, nb_levels, &block)
    s0

    target_assoc = [association] * nb_levels
    assert_wa(0, target_assoc)

    current = s0
    nb_levels.times do |i|
      current = current.create_assoc!(association, nil, skip_attributes: true)
      assert_wa(0, target_assoc) unless i == nb_levels - 1
    end

    assert_wa(1, target_assoc)
  rescue Minitest::Assertion
    # Adding more of the backtrace to the message to make it easier to know where things failed.
    raise $!, "#{$!}\n#{Minitest.filter_backtrace($!.backtrace).join("\n")}", $!.backtrace
  end

  let(:s0) { RecursiveS.create! }
  let(:s0_from) { RecursiveS.where(id: RecursiveS.minimum(:id)) }

  (1..2).each do |nb_levels|
    it "_* handles #{nb_levels} levels of recursive belongs_to association(s) correctly" do
      check_recursive_association(:b1, nb_levels)
    end

    it "_* handles #{nb_levels} levels of recursive has_many association(s) correctly" do
      check_recursive_association(:m1, nb_levels)
    end

    it "_* handles #{nb_levels} levels of recursive has_one association(s) correctly" do
      skip if Test::SelectedDBHelper == Test::MySQL
      check_recursive_association(:o1, nb_levels)
    end

    it "_* handles #{nb_levels} levels of recursive has_and_belongs_to_many association(s) correctly" do
      check_recursive_association(:z1, nb_levels)
    end

    it "_* handles #{nb_levels} levels of recursive polymorphic has_many association(s) correctly" do
      check_recursive_association(:mp1, nb_levels)
    end

    it "_* handles #{nb_levels} levels of recursive polymorphic has_one association(s) correctly" do
      skip if Test::SelectedDBHelper == Test::MySQL
      check_recursive_association(:op1, nb_levels)
    end
  end
end
