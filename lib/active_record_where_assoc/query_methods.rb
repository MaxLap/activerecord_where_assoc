# frozen_string_literal: true

require_relative "helpers"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module QueryMethods
    NestWithExistsBlock = lambda do |wrapping_scope, nested_scope, exists_prefix = ""|
      sql = "#{exists_prefix}EXISTS (#{nested_scope.select('0').to_sql})"

      wrapping_scope.where(sql)
    end

    NestWithSumBlock = lambda do |wrapping_scope, nested_scope|
      # Need the double parentheses
      sql = "SUM((#{nested_scope.to_sql}))"

      # Unscoping in case some scopes did a select
      wrapping_scope.unscope(:select).select(sql)
    end

    def where_assoc_exists(association_name, given_scope = nil, &block)
      nested_relation = relation_on_association(association_name, given_scope, block, NestWithExistsBlock)
      NestWithExistsBlock.call(self, nested_relation)
    end

    def where_assoc_not_exists(association_name, given_scope = nil, &block)
      nested_relation = relation_on_association(association_name, given_scope, block, NestWithExistsBlock)
      NestWithExistsBlock.call(self, nested_relation, "NOT ")
    end

    def where_assoc_count(nb, operator, association_name, given_scope = nil, &block)
      deepest_scope_mod = lambda do |deepest_scope|
        deepest_scope = Helpers.apply_proc_scope(deepest_scope, block) if block

        deepest_scope.unscope(:select).select("COUNT(*)")
      end

      nested_relation = relation_on_association(association_name, given_scope, deepest_scope_mod, NestWithSumBlock)
      operator = case operator.to_s
                 when "=="
                   "="
                 when "!="
                   "<>"
                 else
                   operator
                 end

      where("#{nb} #{operator} COALESCE((#{nested_relation.to_sql}), 0)")
    end


    def relation_on_association(association_names_path, given_scope = nil, last_assoc_block = nil, nest_assocs_block = nil)
      association_names_path = Array.wrap(association_names_path)

      if association_names_path.size > 1
        recursive_scope_block = lambda do |scope|
          nested_scope = scope.relation_on_association(association_names_path[1..-1], given_scope, last_assoc_block, nest_assocs_block)
          nest_assocs_block.call(scope, nested_scope)
        end

        relation_on_direct_association(association_names_path.first, nil, recursive_scope_block, nest_assocs_block)
      else
        relation_on_direct_association(association_names_path.first, given_scope, last_assoc_block, nest_assocs_block)
      end
    end

    def relation_on_direct_association(association_name, given_scope = nil, last_assoc_block = nil, nest_assocs_block = nil)
      association_name = Helpers.normalize_association_name(association_name)
      final_reflection = _reflections[association_name]

      if final_reflection.nil?
        # Need to use build because this exception expects a record...
        raise ActiveRecord::AssociationNotFoundError.new(self.klass.new, association_name)
      end
      if final_reflection.macro == :belongs_to && final_reflection.options[:polymorphic]
        raise NotImplementedError, "Can't deal with polymorphic belongs_to"
      end

      nested_scope = nil
      wrapping_scope = nil

      # Chain deals with through stuff
      # We will start with the reflection that points on the final model, and slowly move back to the reflection
      # that points on the model closest to self
      refl_and_cons_chain = Helpers.chain_reflection_and_constraints(final_reflection)
      skip_next = false

      refl_and_cons_chain.each_with_index do |(reflection, constraints), i|
        if skip_next
          skip_next = false
          next
        end

        next_refl_and_cons = refl_and_cons_chain[i + 1]
        next_reflection = next_refl_and_cons.first if next_refl_and_cons
        parent_reflection = Helpers.parent_reflection(reflection)
        if parent_reflection && parent_reflection.macro == :has_and_belongs_to_many
          # SELECT ... FROM *join_table* INNER JOIN *target_table* ON ...
          # This is the internal association made on the internal model of the habtm

          # Simply using next_reflection.klass.default_scoped.joins(reflection.name) would be great,
          # except we cannot add a given_scope afterward because we are on the wrong "base class", and we can't
          # do #merge because of the LEW crap.
          # So we must do the joins ourself!
          sub_join_contraints = Helpers.join_constraints(reflection, next_reflection, self.klass)
          wrapping_scope = reflection.klass.default_scoped.joins(<<-SQL)
            INNER JOIN #{next_reflection.quoted_table_name} ON #{sub_join_contraints.to_sql}
          SQL

          constraint_allowed_lim_off = reflection.scope

          next_next_refl_and_cons = refl_and_cons_chain[i + 2]
          next_next_reflection = next_next_refl_and_cons.first if next_next_refl_and_cons

          join_constaints = Helpers.join_constraints(next_reflection, next_next_reflection, self.klass)

          # We dealt with next_reflection here by doing a join, so that limit / offset can be applied correctly
          # So nothing is needed for it's iteration
          skip_next = true
        else
          wrapping_scope = reflection.klass.default_scoped
          constraint_allowed_lim_off = reflection.send(:actual_source_reflection).scope
          join_constaints = Helpers.join_constraints(reflection, next_reflection, self.klass)
        end

        constraints.each do |callable|
          relation = reflection.klass.unscoped.instance_exec(&callable)

          if callable != constraint_allowed_lim_off
            if relation.limit_value
              raise LimitFromThroughScopeError, "#limit from an association's scope is only supported on direct associations, not a through."
            end

            if relation.offset_value
              raise OffsetFromThroughScopeError, "#offset from an association's scope is only supported on direct associations, not a through."
            end
          end

          # Need to use merge to replicate the Last Equality Wins behavior of associations
          # https://github.com/rails/rails/issues/7365
          # See also the test/tests/wa_last_equality_wins_test.rb for an explanation
          wrapping_scope = wrapping_scope.merge(relation)
        end

        wrapping_scope = wrapping_scope.where(join_constaints)

        wrapping_scope = wrapping_scope.unscope(:limit, :offset, :order) if reflection.macro == :belongs_to
        wrapping_scope = wrapping_scope.limit(1) if reflection.macro == :has_one

        # Order is useless without either limit or offset
        wrapping_scope = wrapping_scope.unscope(:order) if !wrapping_scope.limit_value && !wrapping_scope.offset_value

        if wrapping_scope.limit_value
          if %w(mysql mysql2).include?(connection.adapter_name.downcase)
            raise MySQLIsTerribleError, "Associations/default_scopes with a limit are not supported for MySQL"
          end

          # We only check the records that would be returned by the associations if called on the model. If:
          # * the scope of the association has a limit
          # * the default scope of the model has a limit
          # * the association is a has_one
          # Then not every records that match a naive join would be returned. So we first restrict the query to
          # only the records that would be in the range of limit and offset.
          #
          # Note that if the #where_assoc_* block adds a limit or an offset, it has no effect. This is intended.
          # An argument could be made for it to maybe make sense for #where_assoc_count, not sure why that would
          # be useful.

          if klass.table_name.include?(".")
            # This works universally, but seems to have slower performances.. Need to test if there is an alternative way
            # of expressing this...
            # TODO: Investigate a way to improve performances, or maybe require a flag to do it this way?
            # We use unscoped to avoid duplicating the conditions in the query, which is noise. (unless if it
            # could helps the query planner of the DB, if someone can show it to be worth it, then this can be changed.)

            wrapping_scope = reflection.klass.unscoped.where(id: wrapping_scope)
          else
            # This works as long as the table_name doesn't have a schema/database, since we need to use an alias
            # with the table name to make scopes and everything else work as expected.

            # We use unscoped to avoid duplicating the conditions in the query, which is noise. (unless if it
            # could helps the query planner of the DB, if someone can show it to be worth it, then this can be changed.)
            wrapping_scope = reflection.klass.unscoped.from("(#{wrapping_scope.to_sql}) #{reflection.klass.table_name}")
          end
        end

        if i.zero?
          wrapping_scope = wrapping_scope.where(given_scope) if given_scope
          wrapping_scope = Helpers.apply_proc_scope(wrapping_scope, last_assoc_block) if last_assoc_block
        end

        # Those make no sense since we are only limiting the value that would match, using conditions
        wrapping_scope = wrapping_scope.unscope(:limit, :order, :offset)

        if nested_scope
          wrapping_scope = nest_assocs_block.call(wrapping_scope, nested_scope)
        end

        nested_scope = wrapping_scope
      end

      wrapping_scope
    end
  end
end
