# frozen_string_literal: true

require_relative "active_record_compat"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module CoreLogic
    # Arel table used for aliasing when handling recursive associations (such as parent/children)
    ALIAS_TABLE = Arel::Table.new("_ar_where_assoc_alias_")

    # Block used when nesting associations for a where_assoc_[not_]exists
    # Will apply the nested scope to the wrapping_scope with: where("EXISTS (SELECT... *nested_scope*)")
    # exists_prefix: raw sql prefix to the EXISTS, ex: 'NOT '
    NestWithExistsBlock = lambda do |wrapping_scope, nested_scope, exists_prefix = ""|
      sql = "#{exists_prefix}EXISTS (#{nested_scope.select('1').to_sql})"

      wrapping_scope.where(sql)
    end

    # Block used when nesting associations for a where_assoc_count
    # Will apply the nested scope to the wrapping_scope with: select("SUM(SELECT... *nested_scope*)")
    NestWithSumBlock = lambda do |wrapping_scope, nested_scope|
      # Need the double parentheses
      sql = "SUM((#{nested_scope.to_sql}))"

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

    # Returns a new relation, which is the result of filtering base_relation
    # based on if a record for the specified association of the model exists.
    #
    # See #where_assoc_exists in query_methods.rb for usage details.
    def self.do_where_assoc_exists(base_relation, association_name, given_scope, options, &block)
      nested_relation = relation_on_association(base_relation, association_name, given_scope, options, block, NestWithExistsBlock)
      NestWithExistsBlock.call(base_relation, nested_relation)
    end

    # Returns a new relation, which is the result of filtering base_relation
    # based on if a record for the specified association of the model doesn't exist.
    #
    # See #where_assoc_exists in query_methods.rb for usage details.
    def self.do_where_assoc_not_exists(base_relation, association_name, given_scope, options, &block)
      nested_relation = relation_on_association(base_relation, association_name, given_scope, options, block, NestWithExistsBlock)
      NestWithExistsBlock.call(base_relation, nested_relation, "NOT ")
    end

    # Returns a new relation, which is the result of filtering base_relation
    # based on how many records for the specified association of the model exists.
    #
    # See #where_assoc_exists and #where_assoc_count in query_methods.rb for usage details.
    def self.do_where_assoc_count(base_relation, left_operand, operator, association_name, given_scope, options, &block)
      deepest_scope_mod = lambda do |deepest_scope|
        deepest_scope = apply_proc_scope(deepest_scope, block) if block

        deepest_scope.unscope(:select).select("COUNT(*)")
      end

      nested_relation = relation_on_association(base_relation, association_name, given_scope, options, deepest_scope_mod, NestWithSumBlock)

      sql = sql_for_count_operator(left_operand, operator, "COALESCE((#{nested_relation.to_sql}), 0)")
      base_relation.where(sql)
    end

    # Returns a relation on the associated model(s) meant to be embedded in a query
    # association_names_path: can be an array of association names or a single one
    def self.relation_on_association(base_relation, association_names_path, given_scope, options, last_assoc_block, nest_assocs_block)
      validate_options(options)
      association_names_path = Array.wrap(association_names_path)

      if association_names_path.size > 1
        recursive_scope_block = lambda do |scope|
          nested_scope = relation_on_association(scope, association_names_path[1..-1], given_scope, options, last_assoc_block, nest_assocs_block)
          nest_assocs_block.call(scope, nested_scope)
        end

        relation_on_one_association(base_relation, association_names_path.first, nil, options, recursive_scope_block, nest_assocs_block)
      else
        relation_on_one_association(base_relation, association_names_path.first, given_scope, options, last_assoc_block, nest_assocs_block)
      end
    end

    # Returns a relation on the associated model meant to be embedded in a query
    def self.relation_on_one_association(base_relation, association_name, given_scope, options, last_assoc_block, nest_assocs_block)
      relation_klass = base_relation.klass
      final_reflection = fetch_reflection(relation_klass, association_name)

      nested_scope = nil
      current_scope = nil

      # Chain deals with through stuff
      # We will start with the reflection that points on the final model, and slowly move back to the reflection
      # that points on the model closest to self
      # Each step, we get all of the scoping lambdas that were defined on associations that apply for
      # the reflection's target
      # Basically, we start from the deepest part of the query and wrap it up
      reflection_chain, constaints_chain = ActiveRecordCompat.chained_reflection_and_chained_constraints(final_reflection)
      skip_next = false

      reflection_chain.each_with_index do |reflection, i|
        if skip_next
          skip_next = false
          next
        end

        # the 2nd part of has_and_belongs_to_many is handled at the same time as the first.
        skip_next = true if actually_has_and_belongs_to_many?(reflection)

        wrapper_scope, current_scope = initial_scope_from_reflection(reflection_chain[i..-1], constaints_chain[i])

        current_scope = process_association_step_limits(current_scope, reflection, relation_klass, options)

        if i.zero?
          current_scope = current_scope.where(given_scope) if given_scope
          current_scope = apply_proc_scope(current_scope, last_assoc_block) if last_assoc_block
        end

        # Those make no sense since we are only limiting the value that would match, using conditions
        current_scope = current_scope.unscope(:limit, :order, :offset)
        current_scope = nest_assocs_block.call(current_scope, nested_scope) if nested_scope
        current_scope = nest_assocs_block.call(wrapper_scope, current_scope) if wrapper_scope

        nested_scope = current_scope
      end

      current_scope
    end

    def self.fetch_reflection(relation_klass, association_name)
      association_name = ActiveRecordCompat.normalize_association_name(association_name)
      reflection = relation_klass._reflections[association_name]

      if reflection.nil?
        # Need to use build because this exception expects a record...
        raise ActiveRecord::AssociationNotFoundError.new(relation_klass.new, association_name)
      end
      if reflection.macro == :belongs_to && reflection.options[:polymorphic]
        raise NotImplementedError, "Can't deal with polymorphic belongs_to"
      end

      reflection
    end

    def self.initial_scope_from_reflection(reflection_chain, constraints)
      reflection = reflection_chain.first
      current_scope = reflection.klass.default_scoped

      if actually_has_and_belongs_to_many?(reflection)
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
        # would be great, except we cannot add a given_scope afterward because we are on the wrong "base class",
        # and we can't do #merge because of the LEW crap.
        # So we must do the joins ourself!
        _wrapper, sub_join_contraints = wrapper_and_join_constraints(reflection)
        next_reflection = reflection_chain[1]

        current_scope = current_scope.joins(<<-SQL)
            INNER JOIN #{next_reflection.klass.quoted_table_name} ON #{sub_join_contraints.to_sql}
        SQL

        wrapper_scope, join_constaints = wrapper_and_join_constraints(next_reflection, habtm_other_reflection: reflection)
      else
        wrapper_scope, join_constaints = wrapper_and_join_constraints(reflection)
      end

      constraint_allowed_lim_off = constraint_allowed_lim_off_from(reflection)

      constraints.each do |callable|
        relation = reflection.klass.unscoped.instance_exec(&callable)

        if callable != constraint_allowed_lim_off
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

      [wrapper_scope, current_scope.where(join_constaints)]
    end

    def self.constraint_allowed_lim_off_from(reflection)
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

    def self.process_association_step_limits(current_scope, reflection, relation_klass, options)
      return current_scope.unscope(:limit, :offset, :order) if user_defined_actual_source_reflection(reflection).macro == :belongs_to

      current_scope = current_scope.limit(1) if reflection.macro == :has_one

      current_scope = current_scope.unscope(:limit, :offset) if option_value(options, :ignore_limit)

      # Order is useless without either limit or offset
      current_scope = current_scope.unscope(:order) if !current_scope.limit_value && !current_scope.offset_value

      return current_scope unless current_scope.limit_value || current_scope.offset_value
      if %w(mysql mysql2).include?(relation_klass.connection.adapter_name.downcase)
        msg = String.new
        msg << "Associations and default_scopes with a limit or offset are not supported for MySQL (this includes has_many). "
        msg << "Use ignore_limit: true to ignore both limit and offset, and treat has_one like has_many. "
        msg << "See https://github.com/MaxLap/activerecord_where_assoc/tree/ignore_limits#mysql-doesnt-support-sub-limit for details."
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
        relation.instance_exec(&proc_scope) || relation
      else
        proc_scope.call(relation) || relation
      end
    end

    def self.build_wrapper_scope_for_recursive_association(reflection)
      table = reflection.klass.arel_table
      primary_key = reflection.klass.primary_key
      foreign_klass = reflection.send(:actual_source_reflection).active_record

      wrapper_scope = foreign_klass.base_class.unscoped
      wrapper_scope = wrapper_scope.from("#{table.name} #{ALIAS_TABLE.name}")
      wrapper_scope = wrapper_scope.where(table[primary_key].eq(ALIAS_TABLE[primary_key]))
      wrapper_scope
    end

    def self.wrapper_and_join_constraints(reflection, options = {})
      join_keys = ActiveRecordCompat.join_keys(reflection)

      key = join_keys.key
      foreign_key = join_keys.foreign_key

      table = reflection.klass.arel_table
      foreign_klass = reflection.send(:actual_source_reflection).active_record
      foreign_table = foreign_klass.arel_table

      habtm_other_reflection = options[:habtm_other_reflection]
      habtm_other_table = habtm_other_reflection.klass.arel_table if habtm_other_reflection

      if (habtm_other_table || table).name == foreign_table.name
        wrapper_scope = build_wrapper_scope_for_recursive_association(habtm_other_reflection || reflection)
        foreign_table = ALIAS_TABLE
      end

      constraints = table[key].eq(foreign_table[foreign_key])

      if reflection.type
        # Handing of the polymorphic has_many/has_one's type column
        constraints = constraints.and(table[reflection.type].eq(foreign_klass.base_class.name))
      end

      [wrapper_scope, constraints]
    end

    def self.has_and_belongs_to_many?(reflection) # rubocop:disable Naming/PredicateName
      parent = ActiveRecordCompat.parent_reflection(reflection)
      parent && parent.macro == :has_and_belongs_to_many
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

      v1 = 0 if v1 == -Float::INFINITY

      return sql_for_count_operator(v1, RIGHT_INFINITE_RANGE_OPERATOR_MAP.fetch(operator), right_sql) if v2 == Float::INFINITY

      # Its int or a float with no mantissa, exclude_end? means -1
      v2 -= 1 if left_operand.exclude_end? && v2 % 1 == 0

      "#{right_sql} #{RANGE_OPERATOR_MAP.fetch(operator)} #{v1} AND #{v2}"
    end
  end
end
