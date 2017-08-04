# frozen_string_literal: true

require_relative "helpers"

module ActiveRecordWhereAssoc
  module QueryMethods
    def where_assoc_exists(association_name, given_scope = nil, &block)
      nested_relation = relation_on_association(association_name, given_scope, &block).select(0)
      res_relation = where(Arel::Nodes::Exists.new(nested_relation.ast))
      # Using an Arel::Node in #where doesn't allow passing the matching binds, so we do it by hand...
      res_relation.where_clause.binds.concat(nested_relation.where_clause.binds)
      res_relation
    end

    def where_assoc_not_exists(association_name, given_scope = nil, &block)
      nested_relation = relation_on_association(association_name, given_scope, &block).select(0)
      res_relation = where(Arel::Nodes::Exists.new(nested_relation.ast).not)
      # Using an Arel::Node in #where doesn't allow passing the matching binds, so we do it by hand...
      res_relation.where_clause.binds.concat(nested_relation.where_clause.binds)
      res_relation
    end

    def where_assoc_count(nb, operator, association_name, given_scope = nil, &block)
      nested_relation = relation_on_association(association_name, given_scope, &block)
      nested_relation = nested_relation.select(Arel::Nodes::Count.new([Arel.star]))
      where("#{nb} #{operator} (#{nested_relation.to_sql})")
    end


    def relation_on_association(association_names_path, given_scope = nil, &block)
      association_names_path = Array.wrap(association_names_path)

      if association_names_path.size > 1
        relation_on_direct_association(association_names_path.first) do |model_scope|
          model_scope.where_assoc_exists(association_names_path[1..-1], given_scope, &block)
        end
      else
        relation_on_direct_association(association_names_path.first, given_scope, &block)
      end
    end

    def relation_on_direct_association(association_name, given_scope = nil, &block)
      association_name = association_name.to_s
      final_reflection = reflections[association_name]

      if final_reflection.nil?
        # Need to use build because this exception expects a record...
        raise ActiveRecord::AssociationNotFoundError.new(self.build, association_name)
      end
      raise "Can't deal with polymorphic belongs_to" if final_reflection.macro == :belongs_to && final_reflection.options[:polymorphic]

      nested_scope = nil
      wrapping_scope = nil

      # Chain deals with through stuff
      chain = final_reflection.chain
      chain.each_with_index do |reflection, i|
        next_reflection = chain[i + 1]
        wrapping_scope = reflection.klass.default_scoped

        reflection.constraints.each do |callable|
          wrapping_scope = wrapping_scope.instance_exec(&callable)
        end

        # Can use #build_join_constraint on reflection in rails 5.2
        join_keys = Helpers.join_keys(reflection)
        key = join_keys.key
        foreign_key = join_keys.foreign_key

        table = reflection.klass.arel_table
        foreign_klass = next_reflection ? next_reflection.klass : self.klass
        foreign_table = foreign_klass.arel_table

        wrapping_scope = wrapping_scope.where(table[key].eq(foreign_table[foreign_key]))

        if reflection.macro == :has_one
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
            # TODO: Use Arel for this?
            # We use unscoped to avoid duplicating the conditions in the query, which is noise
            wrapping_scope = reflection.klass.unscoped.from("(#{wrapping_scope.limit(1).to_sql}) #{reflection.klass.table_name}")
          end
        else
          # TODO: remove limit and order, they are useless. Probably better to do that after the given_scope is used
          nil
        end

        if i.zero?
          wrapping_scope = wrapping_scope.merge(Helpers.unscoped_relation_from(reflection.klass, given_scope)) if given_scope
          if block
            yielded_scope = yield wrapping_scope
            wrapping_scope = yielded_scope if yielded_scope
          end
        end

        if nested_scope
          wrapping_scope = wrapping_scope.where(Arel::Nodes::Exists.new(nested_scope.select(0).ast))
          # Using an Arel::Node in #where doesn't allow passing the matching binds, so we do it by hand...
          wrapping_scope.where_clause.binds.concat(nested_scope.where_clause.binds)
        end

        nested_scope = wrapping_scope
      end

      wrapping_scope
    end
  end
end
