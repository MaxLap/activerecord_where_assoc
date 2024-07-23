# frozen_string_literal: true

require_relative "active_record_compat"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module CoreLogic
    # Arel table used for aliasing when handling recursive associations (such as parent/children)
    ALIAS_TABLE = Arel::Table.new("_ar_where_assoc_alias_")

    # Returns the SQL for checking if any of the received relation exists.
    # Uses a OR if there are multiple relations.
    # => "EXISTS (SELECT... *relation1*) OR EXISTS (SELECT... *relation2*)"
    def self.sql_for_any_exists(relations)
      relations = [relations] unless relations.is_a?(Array)
      relations = relations.reject { |rel| ActiveRecordCompat.null_relation?(rel) }
      sqls = relations.map { |rel| "EXISTS (#{rel.select('1').to_sql})" }
      if sqls.size > 1
        "(#{sqls.join(" OR ")})" # Parens needed when embedding the sql in a `where`, because the OR could make things wrong
      elsif sqls.size == 1
        sqls.first
      else
        "0=1"
      end
    end

    # Block used when nesting associations for a where_assoc_[not_]exists
    NestWithExistsBlock = lambda do |wrapping_scope, nested_scopes|
      wrapping_scope.where(sql_for_any_exists(nested_scopes))
    end

    # Returns the SQL for getting the sum of of the received relations
    # => "SUM((SELECT... *relation1*)) + SUM((SELECT... *relation2*))"
    def self.sql_for_sum_of_counts(relations)
      relations = [relations] unless relations.is_a?(Array)
      relations = relations.reject { |rel| ActiveRecordCompat.null_relation?(rel) }
      # Need the double parentheses
      relations.map { |rel| "SUM((#{rel.to_sql}))" }.join(" + ").presence || "0"
    end

    # Block used when nesting associations for a where_assoc_count
    NestWithSumBlock = lambda do |wrapping_scope, nested_scopes|
      sql = sql_for_sum_of_counts(nested_scopes)
      wrapping_scope.unscope(:select).select(sql)
    end

    # List of available options, used for validation purposes.
    VALID_OPTIONS_KEYS = ActiveRecordWhereAssoc.default_options.keys.freeze

    def self.validate_options(options)
      invalid_keys = options.keys - VALID_OPTIONS_KEYS
      raise ArgumentError, "Invalid option keys received: #{invalid_keys.join(', ')}" unless invalid_keys.empty?
    end

    # Gets the value from the options or fallback to default
    def self.option_value(options, key)
      options.fetch(key) { ActiveRecordWhereAssoc.default_options[key] }
    end

    # Returns the SQL condition to check if the specified association of the record_class exists (has records).
    #
    # See RelationReturningMethods#where_assoc_exists or SqlReturningMethods#assoc_exists_sql for usage details.
    def self.assoc_exists_sql(record_class, association_names, given_conditions, options, &block)
      nested_relations = relations_on_association(record_class, association_names, given_conditions, options, block, NestWithExistsBlock)
      sql_for_any_exists(nested_relations)
    end

    # Returns the SQL condition to check if the specified association of the record_class doesn't exist (has no records).
    #
    # See RelationReturningMethods#where_assoc_not_exists or SqlReturningMethods#assoc_not_exists_sql for usage details.
    def self.assoc_not_exists_sql(record_class, association_names, given_conditions, options, &block)
      nested_relations = relations_on_association(record_class, association_names, given_conditions, options, block, NestWithExistsBlock)
      "NOT #{sql_for_any_exists(nested_relations)}"
    end

    # This does not return an SQL condition. Instead, it returns only the SQL to count the number of records for the specified
    # association.
    #
    # See SqlReturningMethods#only_assoc_count_sql for usage details.
    def self.only_assoc_count_sql(record_class, association_names, given_conditions, options, &block)
      deepest_scope_mod = lambda do |deepest_scope|
        deepest_scope = apply_proc_scope(deepest_scope, block) if block

        deepest_scope.unscope(:select).select("COUNT(*)")
      end

      nested_relations = relations_on_association(record_class, association_names, given_conditions, options, deepest_scope_mod, NestWithSumBlock)
      nested_relations = nested_relations.reject { |rel| ActiveRecordCompat.null_relation?(rel) }
      nested_relations.map { |nr| "COALESCE((#{nr.to_sql}), 0)" }.join(" + ").presence || "0"
    end

    # Returns the SQL condition to check if the specified association of the record_class has the desired number of records.
    #
    # See RelationReturningMethods#where_assoc_count or SqlReturningMethods#compare_assoc_count_sql for usage details.
    def self.compare_assoc_count_sql(record_class, left_operand, operator, association_names, given_conditions, options, &block)
      right_sql = only_assoc_count_sql(record_class, association_names, given_conditions, options, &block)

      sql_for_count_operator(left_operand, operator, right_sql)
    end

    # Returns relations on the associated model meant to be embedded in a query
    # Will only return more than one association when there are polymorphic belongs_to
    # association_names: can be an array of association names or a single one
    def self.relations_on_association(record_class, association_names, given_conditions, options, last_assoc_block, nest_assocs_block)
      validate_options(options)
      association_names = Array.wrap(association_names)
      _relations_on_association_recurse(record_class, association_names, given_conditions, options, last_assoc_block, nest_assocs_block)
    end

    def self._relations_on_association_recurse(record_class, association_names, given_conditions, options, last_assoc_block, nest_assocs_block)
      if association_names.size > 1
        recursive_scope_block = lambda do |scope|
          nested_scope = _relations_on_association_recurse(scope,
                                                           association_names[1..-1],
                                                           given_conditions,
                                                           options,
                                                           last_assoc_block,
                                                           nest_assocs_block)
          nest_assocs_block.call(scope, nested_scope)
        end

        relations_on_one_association(record_class, association_names.first, nil, options, recursive_scope_block, nest_assocs_block)
      else
        relations_on_one_association(record_class, association_names.first, given_conditions, options, last_assoc_block, nest_assocs_block)
      end
    end

    # Returns relations on the associated model meant to be embedded in a query
    # Will return more than one association only for polymorphic belongs_to
    def self.relations_on_one_association(record_class, association_name, given_conditions, options, last_assoc_block, nest_assocs_block)
      final_reflection = fetch_reflection(record_class, association_name)

      check_reflection_validity!(final_reflection)

      nested_scopes = nil
      current_scopes = nil

      # Chain deals with through stuff
      # We will start with the reflection that points on the final model, and slowly move back to the reflection
      # that points on the model closest to self
      # Each step, we get all of the scoping lambdas that were defined on associations that apply for
      # the reflection's target
      # Basically, we start from the deepest part of the query and wrap it up
      reflection_chain, constraints_chain = ActiveRecordCompat.chained_reflection_and_chained_constraints(final_reflection)
      skip_next = false

      reflection_chain.each_with_index do |reflection, i|
        if skip_next
          skip_next = false
          next
        end

        # the 2nd part of has_and_belongs_to_many is handled at the same time as the first.
        skip_next = true if actually_has_and_belongs_to_many?(reflection)

        init_scopes = initial_scopes_from_reflection(record_class, reflection_chain[i..-1], constraints_chain[i], options)
        current_scopes = init_scopes.map do |alias_scope, current_scope, klass_scope|
          current_scope = process_association_step_limits(current_scope, reflection, record_class, options)

          if i.zero?
            current_scope = current_scope.where(given_conditions) if given_conditions
            if klass_scope
              if klass_scope.respond_to?(:call)
                current_scope = apply_proc_scope(current_scope, klass_scope)
              else
                current_scope = current_scope.where(klass_scope)
              end
            end
            current_scope = apply_proc_scope(current_scope, last_assoc_block) if last_assoc_block
          end

          # Those make no sense since at this point, we are only limiting the value that would match using conditions
          # Those could have been added by the received block, so just remove them
          current_scope = current_scope.unscope(:limit, :order, :offset)

          current_scope = nest_assocs_block.call(current_scope, nested_scopes) if nested_scopes
          current_scope = nest_assocs_block.call(alias_scope, current_scope) if alias_scope
          current_scope
        end

        nested_scopes = current_scopes
      end

      current_scopes
    end

    def self.fetch_reflection(relation_klass, association_name)
      association_name = ActiveRecordCompat.normalize_association_name(association_name)
      reflection = relation_klass._reflections[association_name]

      if reflection.nil?
        # Need to use build because this exception expects a record...
        raise ActiveRecord::AssociationNotFoundError.new(relation_klass.new, association_name)
      end

      reflection
    end

    # Can return multiple pairs for polymorphic belongs_to, one per table to look into
    def self.initial_scopes_from_reflection(record_class, reflection_chain, assoc_scopes, options)
      reflection = reflection_chain.first
      actual_source_reflection = user_defined_actual_source_reflection(reflection)

      on_poly_belongs_to = option_value(options, :poly_belongs_to) if poly_belongs_to?(actual_source_reflection)

      classes_with_scope = classes_with_scope_for_reflection(record_class, reflection, options)

      assoc_scope_allowed_lim_off = assoc_scope_to_keep_lim_off_from(reflection)

      classes_with_scope.map do |klass, klass_scope|
        current_scope = klass.default_scoped

        if actually_has_and_belongs_to_many?(actual_source_reflection)
          # has_and_belongs_to_many, behind the scene has a secret model and uses a has_many through.
          # This is the first of those two secret has_many through.
          #
          # In order to handle limit, offset, order correctly on has_and_belongs_to_many,
          # we must do both this reflection and the next one at the same time.
          # Think of it this way, if you have limit 3:
          #   Apply only on 1st step: You check that any of 2nd step for the first 3 of 1st step match
          #   Apply only on 2nd step: You check that any of the first 3 of second step match for any 1st step
          #   Apply over both (as we do): You check that only the first 3 of doing both step match,

          # To create the join, simply using next_reflection.klass.default_scoped.joins(reflection.name)
          # would be great, except we cannot add a given_conditions afterward because we are on the wrong "base class",
          # and we can't do #merge because of the LEW crap.
          # So we must do the joins ourself!
          _wrapper, sub_join_contraints = wrapper_and_join_constraints(record_class, reflection)
          next_reflection = reflection_chain[1]

          current_scope = current_scope.joins(<<-SQL)
              INNER JOIN #{next_reflection.klass.quoted_table_name} ON #{sub_join_contraints.to_sql}
          SQL

          alias_scope, join_constraints = wrapper_and_join_constraints(record_class, next_reflection, habtm_other_reflection: reflection)
        elsif on_poly_belongs_to
          alias_scope, join_constraints = wrapper_and_join_constraints(record_class, reflection, poly_belongs_to_klass: klass)
        else
          alias_scope, join_constraints = wrapper_and_join_constraints(record_class, reflection)
        end

        assoc_scopes.each do |callable|
          relation = klass.unscoped.instance_exec(nil, &callable)

          if callable != assoc_scope_allowed_lim_off
            # I just want to remove the current values without screwing things in the merge below
            # so we cannot use #unscope
            relation.limit_value = nil
            relation.offset_value = nil
            relation.order_values = []
          end

          # Need to use merge to replicate the Last Equality Wins behavior of associations
          # https://github.com/rails/rails/issues/7365
          # See also the test/tests/wa_last_equality_wins_test.rb for an explanation
          current_scope = current_scope.merge(relation)
        end

        [alias_scope, current_scope.where(join_constraints), klass_scope]
      end
    end

    def self.assoc_scope_to_keep_lim_off_from(reflection)
      # For :through associations, it's pretty hard/tricky to apply limit/offset/order of the
      # whole has_* :through. For now, we only apply those of the direct associations from one model
      # to another that the :through uses and we ignore the limit/offset/order from the scope of has_* :through.
      #
      # The exception is for has_and_belongs_to_many, which behind the scene, use a has_many :through.
      # For those, since we know there is no limits on the internal has_many and the belongs_to,
      # we can do a special case and handle their limit. This way, we can treat them the same way we treat
      # the other macros, we only apply the limit/offset/order of the deepest user-define association.
      user_defined_actual_source_reflection(reflection).scope
    end

    def self.classes_with_scope_for_reflection(record_class, reflection, options)
      actual_source_reflection = user_defined_actual_source_reflection(reflection)

      if poly_belongs_to?(actual_source_reflection)
        on_poly_belongs_to = option_value(options, :poly_belongs_to)

        if reflection.options[:source_type]
          [reflection.options[:source_type].safe_constantize].compact
        else
          case on_poly_belongs_to
          when :pluck
            model_for_ids = actual_source_reflection.active_record

            if model_for_ids.abstract_class
              # When the reflection is defined on an abstract model, we fallback to the model
              # on which this was called
              model_for_ids = record_class
            end

            class_names = model_for_ids.distinct.pluck(actual_source_reflection.foreign_type)
            class_names.compact.map!(&:safe_constantize).compact
          when Array, Hash
            array = on_poly_belongs_to.to_a
            bad_class = array.detect { |c, _p| !c.is_a?(Class) || !(c < ActiveRecord::Base) }
            if bad_class.is_a?(ActiveRecord::Base)
              raise ArgumentError, "Must receive the Class of the model, not an instance. This is wrong: #{bad_class.inspect}"
            elsif bad_class
              raise ArgumentError, "Expected #{bad_class.inspect} to be a subclass of ActiveRecord::Base"
            end
            array
          when :raise
            msg = String.new
            if actual_source_reflection == reflection
              msg << "Association #{reflection.name.inspect} is a polymorphic belongs_to. "
            else
              msg << "Association #{reflection.name.inspect} is a :through relation that uses a polymorphic belongs_to"
              msg << "#{actual_source_reflection.name.inspect} as source without without a source_type. "
            end
            msg << "This is not supported by ActiveRecord when doing joins, but it is by WhereAssoc. However, "
            msg << "you must pass the :poly_belongs_to option to specify what to do in this case.\n"
            msg << "See https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods.html#module-ActiveRecordWhereAssoc::RelationReturningMethods-label-3Apoly_belongs_to+option"
            raise ActiveRecordWhereAssoc::PolymorphicBelongsToWithoutClasses, msg
          else
            if on_poly_belongs_to.is_a?(Class) && on_poly_belongs_to < ActiveRecord::Base
              [on_poly_belongs_to]
            else
              raise ArgumentError, "Received a bad value for :poly_belongs_to: #{on_poly_belongs_to.inspect}"
            end
          end
        end
      else
        [reflection.klass]
      end
    end

    # Creates a sub_query that the current_scope gets nested into if there is limit/offset to apply
    def self.process_association_step_limits(current_scope, reflection, relation_klass, options)
      if user_defined_actual_source_reflection(reflection).macro == :belongs_to || option_value(options, :ignore_limit)
        return current_scope.unscope(:limit, :offset, :order)
      end

      # No need to do transformations if this is already a NullRelation
      return current_scope if ActiveRecordCompat.null_relation?(current_scope)

      current_scope = current_scope.limit(1) if reflection.macro == :has_one

      # Order is useless without either limit or offset
      current_scope = current_scope.unscope(:order) if !current_scope.limit_value && !current_scope.offset_value

      return current_scope unless current_scope.limit_value || current_scope.offset_value
      if %w(mysql mysql2).include?(relation_klass.connection.adapter_name.downcase)
        msg = String.new
        msg << "Associations and default_scopes with a limit or offset are not supported for MySQL (this includes has_many). "
        msg << "Use ignore_limit: true to ignore both limit and offset, and treat has_one like has_many. "
        msg << "See https://github.com/MaxLap/activerecord_where_assoc#mysql-doesnt-support-sub-limit for details."
        raise MySQLDoesntSupportSubLimitError, msg
      end

      # We only check the records that would be returned by the associations if called on the model. If:
      # * the association has a limit in its lambda
      # * the default scope of the model has a limit
      # * the association is a has_one
      # Then not every records that match a naive join would be returned. So we first restrict the query to
      # only the records that would be in the range of limit and offset.
      #
      # Note that if the #where_assoc_* block adds a limit or an offset, it has no effect. This is intended.
      # An argument could be made for it to maybe make sense for #where_assoc_count, not sure why that would
      # be useful.

      if reflection.klass.table_name.include?(".") || option_value(options, :never_alias_limit)
        # We use unscoped to avoid duplicating the conditions in the query, which is noise. (unless it
        # could helps the query planner of the DB, if someone can show it to be worth it, then this can be changed.)

        reflection.klass.unscoped.where(reflection.klass.primary_key.to_sym => current_scope)
      else
        # This works as long as the table_name doesn't have a schema/database, since we need to use an alias
        # with the table name to make scopes and everything else work as expected.

        # We use unscoped to avoid duplicating the conditions in the query, which is noise. (unless if it
        # could helps the query planner of the DB, if someone can show it to be worth it, then this can be changed.)
        reflection.klass.unscoped.from("(#{current_scope.to_sql}) #{reflection.klass.table_name}")
      end
    end

    # Apply a proc used as scope
    # If it can't receive arguments, call the proc with self set to the relation
    # If it can receive arguments, call the proc the relation passed as argument
    def self.apply_proc_scope(relation, proc_scope)
      if proc_scope.arity == 0
        relation.instance_exec(nil, &proc_scope) || relation
      else
        proc_scope.call(relation) || relation
      end
    end

    def self.build_alias_scope_for_recursive_association(reflection, poly_belongs_to_klass)
      klass = poly_belongs_to_klass || reflection.klass
      table = klass.arel_table
      primary_key = klass.primary_key
      foreign_klass = reflection.send(:actual_source_reflection).active_record

      alias_scope = foreign_klass.base_class.unscoped
      alias_scope = alias_scope.from("#{table.name} #{ALIAS_TABLE.name}")
      alias_scope = alias_scope.where(table[primary_key].eq(ALIAS_TABLE[primary_key]))
      alias_scope
    end

    def self.wrapper_and_join_constraints(record_class, reflection, options = {})
      poly_belongs_to_klass = options[:poly_belongs_to_klass]
      join_keys = ActiveRecordCompat.join_keys(reflection, poly_belongs_to_klass)

      key = join_keys.key
      foreign_key = join_keys.foreign_key

      table = (poly_belongs_to_klass || reflection.klass).arel_table
      foreign_klass = reflection.send(:actual_source_reflection).active_record
      if foreign_klass.abstract_class
        # When the reflection is defined on an abstract model, we fallback to the model
        # on which this was called
        foreign_klass = record_class
      end

      foreign_table = foreign_klass.arel_table

      habtm_other_reflection = options[:habtm_other_reflection]
      habtm_other_table = habtm_other_reflection.klass.arel_table if habtm_other_reflection

      if (habtm_other_table || table).name == foreign_table.name
        alias_scope = build_alias_scope_for_recursive_association(habtm_other_reflection || reflection, poly_belongs_to_klass)
        foreign_table = ALIAS_TABLE
      end

      constraints = nil
      constraint_keys = Array.wrap(key)
      constraint_foreign_keys = Array.wrap(foreign_key)
      constraint_key_map = constraint_keys.zip(constraint_foreign_keys)

      constraint_key_map.each do |primary_and_foreign_keys|
        the_primary_key, the_foreign_key = primary_and_foreign_keys 
        the_constraint = table[the_primary_key].eq(foreign_table[the_foreign_key])
        constraints = constraints ? constraints.and(the_constraint) : the_constraint  
      end 

      if reflection.type
        # Handling of the polymorphic has_many/has_one's type column
        constraints = constraints.and(table[reflection.type].eq(foreign_klass.base_class.name))
      end

      if poly_belongs_to_klass
        constraints = constraints.and(foreign_table[reflection.foreign_type].eq(poly_belongs_to_klass.base_class.name))
      end

      [alias_scope, constraints]
    end

    # Because we work using Model._reflections, we don't actually get the :has_and_belongs_to_many.
    # Instead, we get a has_many :through, which is was ActiveRecord created behind the scene.
    # This code detects that a :through is actually a has_and_belongs_to_many.
    def self.has_and_belongs_to_many?(reflection) # rubocop:disable Naming/PredicateName
      parent = ActiveRecordCompat.parent_reflection(reflection)
      parent && parent.macro == :has_and_belongs_to_many
    end

    def self.poly_belongs_to?(reflection)
      reflection.macro == :belongs_to && reflection.options[:polymorphic]
    end

    # Return true if #user_defined_actual_source_reflection is a has_and_belongs_to_many
    def self.actually_has_and_belongs_to_many?(reflection)
      has_and_belongs_to_many?(user_defined_actual_source_reflection(reflection))
    end

    # Returns the deepest user-defined reflection using source_reflection.
    # This is different from #send(:actual_source_reflection) because it stops on
    # has_and_belongs_to_many associations, where as actual_source_reflection would continue
    # down to the belongs_to that is used internally.
    def self.user_defined_actual_source_reflection(reflection)
      loop do
        return reflection if reflection == reflection.source_reflection
        return reflection if has_and_belongs_to_many?(reflection)
        reflection = reflection.source_reflection
      end
    end

    def self.check_reflection_validity!(reflection)
      if ActiveRecordCompat.through_reflection?(reflection)
        # Copied from ActiveRecord
        if reflection.through_reflection.polymorphic?
          # Since deep_cover/builtin_takeover lacks some granularity,
          # it can sometimes happen that it won't display 100% coverage while a regular would
          # be 100%. This happens when multiple banches are on in a single line.
          # For this reason, I split this condition in 2
          if ActiveRecord.const_defined?(:HasOneAssociationPolymorphicThroughError)
            if reflection.has_one?
              raise ActiveRecord::HasOneAssociationPolymorphicThroughError.new(reflection.active_record.name, reflection)
            end
          end
          raise ActiveRecord::HasManyThroughAssociationPolymorphicThroughError.new(reflection.active_record.name, reflection)
        end
        check_reflection_validity!(reflection.through_reflection)
        check_reflection_validity!(reflection.source_reflection)
      end
    end

    # Doing (SQL) BETWEEN v1 AND v2, where v2 is infinite means (SQL) >= v1. However,
    # we place the SQL on the right side, so the operator is flipped to become v1 <= (SQL).
    # Doing (SQL) NOT BETWEEN v1 AND v2 where v2 is infinite means (SQL) < v1. However,
    # we place the SQL on the right side, so the operator is flipped to become v1 > (SQL).
    RIGHT_INFINITE_RANGE_OPERATOR_MAP = { "=" => "<=", "<>" => ">" }.freeze
    # We flip the operators to use when it's about the left-side of the range.
    LEFT_INFINITE_RANGE_OPERATOR_MAP = Hash[RIGHT_INFINITE_RANGE_OPERATOR_MAP.map { |k, v| [k, v.tr("<>", "><")] }].freeze

    RANGE_OPERATOR_MAP = { "=" => "BETWEEN", "<>" => "NOT BETWEEN" }.freeze

    def self.sql_for_count_operator(left_operand, operator, right_sql)
      operator = case operator.to_s
                 when "=="
                   "="
                 when "!="
                   "<>"
                 else
                   operator.to_s
                 end

      return "(#{left_operand}) #{operator} #{right_sql}" unless left_operand.is_a?(Range)

      unless %w(= <>).include?(operator)
        raise ArgumentError, "Operator should be one of '==', '=', '<>' or '!=' when using a Range not: #{operator.inspect}"
      end

      v1 = left_operand.begin
      v2 = left_operand.end || Float::INFINITY

      # We are doing a count and summing them, the lowest possible is 0, so just use that instead of changing the SQL used.
      v1 = 0 if v1 == -Float::INFINITY

      return sql_for_count_operator(v1, RIGHT_INFINITE_RANGE_OPERATOR_MAP.fetch(operator), right_sql) if v2 == Float::INFINITY

      # Its int or a rounded float. Since we are comparing to integer values (count), exclude_end? just means -1
      v2 -= 1 if left_operand.exclude_end? && v2 % 1 == 0

      "#{right_sql} #{RANGE_OPERATOR_MAP.fetch(operator)} #{v1} AND #{v2}"
    end
  end
end
