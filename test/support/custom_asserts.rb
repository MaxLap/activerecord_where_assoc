
# frozen_string_literal: true

# Adds some nice assertions for testing if a match is found or not, and
# testing the behavior of the not_exists variant at the same time.

# TODO: make the ... be the actual arguments

module Minitest::Assertions
  def assert_exists_with_matching_from(start_from, association_name, *args, &block)
    msgs = []
    if !start_from.where_assoc_exists(association_name, *args, &block).exists?
      msgs << "Expected a match but got none for S0.where_assoc_exists(#{association_name.inspect}, ...)"
    end

    if start_from.where_assoc_not_exists(association_name, *args, &block).exists?
      msgs << "Expected no matches but got one for S0.where_assoc_not_exists(#{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  def assert_exists_with_matching(association_name, *args, &block)
    assert_exists_with_matching_from(S0, association_name, *args, &block)
  end

  def assert_exists_without_matching_from(start_from, association_name, *args, &block)
    msgs = []
    if start_from.where_assoc_exists(association_name, *args, &block).exists?
      msgs << "Expected no matches but got one for S0.where_assoc_exists(#{association_name.inspect}, ...)"
    end

    if !start_from.where_assoc_not_exists(association_name, *args, &block).exists?
      msgs << "Expected a match but got none for S0.where_assoc_not_exists(#{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  def assert_exists_without_matching(association_name, *args, &block)
    assert_exists_without_matching_from(S0, association_name, *args, &block)
  end

  def assert_wa_count(expected_count, association_name, *args, &block)
    assert_wa_count_specific(expected_count, expected_count + 1, :==, association_name, *args, &block)
    assert_wa_count_specific(expected_count + 1, expected_count, :!=, association_name, *args, &block)
    assert_wa_count_specific(expected_count, expected_count + 1, :<=, association_name, *args, &block)
    assert_wa_count_specific(expected_count - 1, expected_count, :<, association_name, *args, &block)
    assert_wa_count_specific(expected_count, expected_count - 1, :>=, association_name, *args, &block)
    assert_wa_count_specific(expected_count + 1, expected_count, :>, association_name, *args, &block)
  end

  def assert_wa_count_specific(matching_nb, not_matching_nb, operator, association_name, *args, &block)
    msgs = []
    if !S0.where_assoc_count(matching_nb, operator, association_name, *args, &block).exists?
      msgs << "Expected a match but got none for" \
              " S0.where_assoc_count(matching_nb=#{matching_nb}, :#{operator}, #{association_name.inspect}, ...)"
    end

    if S0.where_assoc_count(not_matching_nb, operator, association_name, *args, &block).exists?
      msgs << "Expected no matches but got one for" \
              " S0.where_assoc_count(not_matching_nb=#{not_matching_nb}, :#{operator}, #{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end
end
