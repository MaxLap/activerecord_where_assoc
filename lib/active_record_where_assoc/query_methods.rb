# frozen_string_literal: true

require_relative "helpers"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module QueryMethods
    NestWithExistsBlock = lambda do |wrapping_scope, nested_scope, exists_prefix = ""|
      # Limit 0 means nothing should be found. We can stop right there then with a false condition.
      # Note that this is needed because SQLite3 doesn't apply the LIMIT(0)
      if nested_scope.limit_value == 0
        return wrapping_scope.where("#{exists_prefix}'EXISTS_WITH_LIMIT_0' = 'SKIP_THE_REST'")
      end

      # Other limit values, and order clauses are ignored in an exists, get rid of them for clarity
      # Note that we allow negative limits by doing this, which some DB would have failed on. I don't think it's an issue.
      nested_scope = nested_scope.unscope(:order, :limit)

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

    # TODO: Document that this makes little sense if any of the scopes on the association or
    #       default_scope or custom condition use joins.
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
      refl_and_cons_chain.each_with_index do |(reflection, constraints), i|
        next_refl_and_cons = refl_and_cons_chain[i + 1]
        next_reflection = next_refl_and_cons.first if next_refl_and_cons

        wrapping_scope = reflection.klass.default_scoped

        constraints.each do |callable|
          # Need to use merge to replicate the Last Equality Wins behavior of associations
          # https://github.com/rails/rails/issues/7365
          # See also the test/tests/wa_last_equality_wins_test.rb for an explanation
          wrapping_scope = wrapping_scope.merge(reflection.klass.unscoped.instance_exec(&callable))
        end

        wrapping_scope = wrapping_scope.where(Helpers.join_constraints(reflection, next_reflection, self.klass))

        if reflection.macro == :has_one
          if %w(mysql mysql2).include?(connection.adapter_name.downcase)
            raise MySQLIsTerribleError, "has_one on models with a table_name that includes the database is not supported for MySQL"
          end

          # We only check the last one that matches the scopes on the associations / default_scope of record.
          # The given scope is applied on the result.
          if klass.table_name.include?(".")
            # This works universally, but seems to have slower performances.. Need to test if there is an alternative way
            # of expressing the above... They should be equivalent, but their performances aren't
            # TODO: Investigate a way to improve performances, or maybe require a flag to do it this way?
            # We use unscoped to avoid duplicating the conditions in the query, which is noise

            wrapping_scope = reflection.klass.unscoped.where(id: wrapping_scope.limit(1))
          else
            # This works as long as the table_name doesn't have a schema, since we need to use an alias
            # with the table name to make scopes and everything else work as expected.

            # We use unscoped to avoid duplicating the conditions in the query, which is noise
            wrapping_scope = reflection.klass.unscoped.from("(#{wrapping_scope.limit(1).to_sql}) #{reflection.klass.table_name}")
          end
        else
          # TODO: remove limit and order, they are useless. Probably better to do that after the given_scope is used
          nil
        end

        if i.zero?
          wrapping_scope = wrapping_scope.where(given_scope) if given_scope
          wrapping_scope = Helpers.apply_proc_scope(wrapping_scope, last_assoc_block) if last_assoc_block
        end

        if nested_scope
          wrapping_scope = nest_assocs_block.call(wrapping_scope, nested_scope)
        end

        nested_scope = wrapping_scope
      end

      wrapping_scope
    end
  end
end
