
# frozen_string_literal: true

# Adds some nice assertions for testing if a match is found or not, and
# testing the behavior of the not_exists variant at the same time.

# TODO: make the ... be the actual arguments

module Minitest::Assertions
  def assert_exists_with_matching(association_name, *args, &block)
    msgs = []
    if !S0.where_assoc_exists(association_name, *args, &block).exists?
      msgs << "Expected a match but got none for S0.where_assoc_exists(#{association_name.inspect}, ...)"
    end

    if S0.where_assoc_not_exists(association_name, *args, &block).exists?
      msgs << "Expected no matches but got one for S0.where_assoc_not_exists(#{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  def assert_exists_without_matching(association_name, *args, &block)
    msgs = []
    if S0.where_assoc_exists(association_name, *args, &block).exists?
      msgs << "Expected no matches but got none for S0.where_assoc_exists(#{association_name.inspect}, ...)"
    end

    if !S0.where_assoc_not_exists(association_name, *args, &block).exists?
      msgs << "Expected a match but got one for S0.where_assoc_not_exists(#{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end
end
