
# frozen_string_literal: true

# Adds some nice assertions for testing if a match is found or not, and
# testing the behavior of the not_exists variant at the same time.

module Minitest::Assertions
  def with_manual_wa_test?
    @with_manual_wa_test = true unless defined?(@with_manual_wa_test)
    @with_manual_wa_test
  end

  def without_manual_wa_test(&block)
    old = with_manual_wa_test?
    @with_manual_wa_test = false
    yield
  ensure
    @with_manual_wa_test = old
  end

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
        from = respond_to?(:s0_from) ? s0_from : S0
        #{shortcut}_from(from, *args, &block)
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

    manual_result = manual_testing_results_from(start_from, matching_nb, operator, association_name, args.first, &block)
    msgs << manual_result if manual_result

    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  def manual_testing_results_from(start_from, matching_nb, operator, association_name, conditions, &block)
    return unless with_manual_wa_test?

    case conditions
    when Hash
      conditions = conditions.symbolize_keys if conditions.is_a?(Hash)
    when nil
      # nothing to do
    else
      raise "Unsupported conditions type for manual test: #{conditions.class.name}. Wrap the check with without_manual_wa_test{ ... }"
    end

    record_sets = start_from.all.map { |record| [record] }
    association_name = [*association_name]
    association_name.each do |assoc|
      record_sets = record_sets.map(&:flatten)
      record_sets = record_sets.map { |records| records.select(&:present?).map(&assoc) }
    end

    record_sets = record_sets.map do |records|
      records.compact.map do |record|
        raise "Manual test cannot handle blocks" if block_given?
        next record unless conditions

        if record.is_a?(ActiveRecord::Associations::CollectionProxy)
          record.where(conditions)
        elsif conditions.is_a?(Hash)
          record if record.attributes.symbolize_keys.slice(*conditions.keys) == conditions
        end
      end
    end
    record_sets = record_sets.map(&:flatten).map(&:compact)

    correct_result = record_sets.any? do |records|
      matching_nb.send(operator, records.size)
    end

    return if correct_result

    "Doing the operations manually through ActiveRecord doesn't give thes expected result. " \
        "Expected to find a result with size #{operator.to_s.tr('<>', '><')} to #{matching_nb}, " \
        "but got these sizes: #{record_sets.map(&:size).uniq.sort}."
  end
end
