
# frozen_string_literal: true

# Adds some nice assertions for testing if a match is found or not, and
# testing the behavior of the not_exists variant at the same time.

module Minitest::Assertions
  [:assert_exists_with_matching,
   :assert_exists_without_matching,
   :assert_wa_count,
   :assert_wa_count_full,
   :assert_wa_count_specific,
   :assert_wa,
   ].each do |shortcut|
    # Using class eval to define a real method instead of using #define_method
    # #define_method made minitest not give the right location for where the assert
    # happened because it scans the backtrace for the first non-assert-like method,
    # and the #define_method added an extra block which wasn't filtered.
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{shortcut}(*args, &block)
        #{shortcut}_from(S0, *args, &block)
      end
    RUBY
  end

  def assert_wa_from(start_from, nb_match_assoc, association_name, *args, &block)
    assert_wa_count_from(start_from, nb_match_assoc, association_name, *args, &block)
    if nb_match_assoc > 0
      assert_exists_with_matching_from(start_from, association_name, *args, &block)
    else
      assert_exists_without_matching_from(start_from, association_name, *args, &block)
    end
  end

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

  def assert_wa_count_from(start_from, expected_count, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count, expected_count + 1, :==, association_name, *args, &block)
  end

  def assert_wa_count_full_from(start_from, expected_count, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count, expected_count + 1, :==, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count + 1, expected_count, :!=, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count, expected_count + 1, :<=, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count - 1, expected_count, :<, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count, expected_count - 1, :>=, association_name, *args, &block)
    assert_wa_count_specific_from(start_from, expected_count + 1, expected_count, :>, association_name, *args, &block)
  end

  def assert_wa_count_specific_from(start_from, matching_nb, not_matching_nb, operator, association_name, *args, &block)
    msgs = []
    if !start_from.where_assoc_count(matching_nb, operator, association_name, *args, &block).exists?
      msgs << "Expected a match but got none for" \
              " S0.where_assoc_count(matching_nb=#{matching_nb}, :#{operator}, #{association_name.inspect}, ...)"
    end

    if start_from.where_assoc_count(not_matching_nb, operator, association_name, *args, &block).exists?
      msgs << "Expected no matches but got one for" \
              " S0.where_assoc_count(not_matching_nb=#{not_matching_nb}, :#{operator}, #{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end
end
