
# frozen_string_literal: true

# Adds some nice assertions for testing if a match is found or not, and
# testing the behavior of the not_exists variant at the same time.

module Minitest::Assertions
  # Just makes things more obvious in a test.
  # Otherwise there is just code doing something and no assertions.
  def assert_nothing_raised
    yield
  end

  def with_wa_default_options(options, &block)
    prev_values = ActiveRecordWhereAssoc.default_options.slice(*options.keys)
    ActiveRecordWhereAssoc.default_options.merge!(options)
    yield
  ensure
    ActiveRecordWhereAssoc.default_options.merge!(prev_values)
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
    exists_relation = start_from.where_assoc_exists(association_name, *args, &block)
    if !exists_relation.to_sql.include?(start_from.assoc_exists_sql(association_name, *args, &block))
      msgs << "Expected query from where_assoc_exists to include the SQL from assoc_exists_sql"
    end
    if !exists_relation.exists?
      msgs << "Expected a match but got none for where_assoc_exists(#{association_name.inspect}, ...)"
    end

    not_exists_relation = start_from.where_assoc_not_exists(association_name, *args, &block)
    if !not_exists_relation.to_sql.include?(start_from.assoc_not_exists_sql(association_name, *args, &block))
      msgs << "Expected query from where_assoc_not_exists to include the SQL from assoc_not_exists_sql"
    end
    if not_exists_relation.exists?
      msgs << "Expected no matches but got one for where_assoc_not_exists(#{association_name.inspect}, ...)"
    end
    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  def assert_exists_without_matching_from(start_from, association_name, *args, &block)
    msgs = []
    exists_relation = start_from.where_assoc_exists(association_name, *args, &block)
    if !exists_relation.to_sql.include?(start_from.assoc_exists_sql(association_name, *args, &block))
      msgs << "Expected query from where_assoc_exists to include the SQL from assoc_exists_sql"
    end
    if exists_relation.exists?
      msgs << "Expected no matches but got one for where_assoc_exists(#{association_name.inspect}, ...)"
    end

    not_exists_relation = start_from.where_assoc_not_exists(association_name, *args, &block)
    if !not_exists_relation.to_sql.include?(start_from.assoc_not_exists_sql(association_name, *args, &block))
      msgs << "Expected query from where_assoc_not_exists to include the SQL from assoc_not_exists_sql"
    end
    if !not_exists_relation.exists?
      msgs << "Expected a match but got none for where_assoc_not_exists(#{association_name.inspect}, ...)"
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
    matching_relation = start_from.where_assoc_count(matching_nb, operator, association_name, *args, &block)
    if !matching_relation.to_sql.include?(start_from.compare_assoc_count_sql(matching_nb, operator, association_name, *args, &block))
      msgs << "Expected query from where_assoc_count to include the SQL from compare_assoc_count_sql"
    end
    if !matching_relation.to_sql.include?(start_from.only_assoc_count_sql(association_name, *args, &block))
      msgs << "Expected query from where_assoc_count to include the SQL from only_assoc_count_sql"
    end
    if !matching_relation.exists?
      msgs << "Expected a match but got none for" \
              " S0.where_assoc_count(matching_nb=#{matching_nb}, :#{operator}, #{association_name.inspect}, ...)"
    end

    non_matching_relation = start_from.where_assoc_count(not_matching_nb, operator, association_name, *args, &block)
    if !non_matching_relation.to_sql.include?(start_from.compare_assoc_count_sql(not_matching_nb, operator, association_name, *args, &block))
      msgs << "Expected query from where_assoc_count to include the SQL from compare_assoc_count_sql"
    end
    if !non_matching_relation.to_sql.include?(start_from.only_assoc_count_sql(association_name, *args, &block))
      msgs << "Expected query from where_assoc_count to include the SQL from compare_assoc_count_sql"
    end
    if non_matching_relation.exists?
      msgs << "Expected no matches but got one for" \
              " S0.where_assoc_count(not_matching_nb=#{not_matching_nb}, :#{operator}, #{association_name.inspect}, ...)"
    end

    manual_result = manual_testing_results_from(start_from, matching_nb, operator, association_name, args.first, &block)
    msgs << manual_result if manual_result

    assert msgs.empty?, msgs.map { |s| "  #{s}" }.join("\n")
  end

  # This is a helper to disable the "manual testing" done by some of the asserts in this file.
  # See manual_testing_results_from for details on those manual tests
  # The tests must be disabled when ActiveRecord has a different behavior than us.
  # examples of when its needed: (limits / offset / has_one) with :through associations
  def without_manual_wa_test(&block)
    old = with_manual_wa_test?
    @with_manual_wa_test = false
    yield
  ensure
    @with_manual_wa_test = old
  end

  def with_manual_wa_test?
    @with_manual_wa_test = true unless defined?(@with_manual_wa_test)
    @with_manual_wa_test
  end

  # This does a "manual" test of the results, but using ActiveRecord and literally walking through the associations and
  # counting the results, to make sure that the expected behavior is also what ActiveRecord does.
  def manual_testing_results_from(start_from, matching_nb, operator, association_name, conditions, &block)
    return unless with_manual_wa_test?

    record_sets = start_from.all.map { |record| [record] }
    association_name = [*association_name]
    association_name.each do |assoc|
      record_sets = record_sets.map { |records| records.select(&:present?).map(&assoc) }
      record_sets = record_sets.map(&:flatten).map(&:compact)
    end

    record_sets = record_sets.map do |records|
      next records if records.blank?

      record_klass = records.first.class.base_class

      scope = record_klass.unscoped.where(record_klass.primary_key => records.map(&:id))
      scope = scope.where(conditions)
      scope = ActiveRecordWhereAssoc::CoreLogic.apply_proc_scope(scope, block) if block
      scope.pluck(*record_klass.primary_key)
    end

    correct_result = record_sets.any? do |records|
      matching_nb.send(operator, records.size)
    end

    return if correct_result

    "Doing the operations manually through ActiveRecord doesn't give the expected result. " \
        "Expected to find a result with size #{operator.to_s.tr('<>', '><')} to #{matching_nb}, " \
        "but got these sizes: #{record_sets.map(&:size).uniq.sort}."
  end
end
