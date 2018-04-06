# frozen_string_literal: true

require_relative "active_record_compat"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module CoreLogic
    # Block used when nesting associations for a where_assoc_[not_]exists
    # Will apply the nested scope to the wrapping_scope with: where("EXISTS (SELECT... *nested_scope*)")
    # exists_prefix: raw sql prefix to the EXISTS, ex: 'NOT '
    NestWithExistsBlock = lambda do |wrapping_scope, nested_scope, exists_prefix = ""|
      sql = "#{exists_prefix}EXISTS (#{nested_scope.select('0').to_sql})"

      wrapping_scope.where(sql)
    end

    # Block used when nesting associations for a where_assoc_count
    # Will apply the nested scope to the wrapping_scope with: select("SUM(SELECT... *nested_scope*)")
    NestWithSumBlock = lambda do |wrapping_scope, nested_scope|
      # Need the double parentheses
      sql = "SUM((#{nested_scope.to_sql}))"

      wrapping_scope.unscope(:select).select(sql)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model exists. Conditions
    # the associated model must match can also be specified.
    #
    # As first argument, you must specify the association to check against. This can be
    # any of the associations on the current relation's model.
    #
    #     # Posts that have at least one comment
    #     Post.where_assoc_exists(:comments)
    #
    # #where_assoc_exists accepts a block to add conditions that the association must match
    # to be accepted for the exist test.
    #
    # === block that receives an argument
    #
    # The block receives a relation on the target association and return a relation with added
    # filters or may return nil.
    #
    #    # Using a where for the added condition
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(spam_flag: true) }
    #
    #    # Applying a scope of the relation
    #    Post.where_assoc_exists(:comments) { |comments| comments.spam_flagged }
    #
    #    # Applying a scope of the relation, using the &:shortcut for procs
    #    Post.where_assoc_exists(:comments, &:spam_flagged)
    #
    # === block that receives no argument
    #
    # Instead of receiving the relation as argument, the relation is used as the "self" of
    # the block.
    #
    #    # Using a where for the added condition
    #    Post.where_assoc_exists(:comments) { where(spam_flag: true) }
    #
    #    # Applying a scope of the relation
    #    Post.where_assoc_exists(:comments) { spam_flagged }
    #
    # The main reason not to use this and use a block with an argument is when you need to
    # call methods on the real self of the block, such as:
    #
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(id: self.something) }
    #
    # === the condition argument (second argument)
    #
    # #where_assoc_exists can receive an argument after the association's name as a shortcut
    # for using a single where call. The argument is passed to #where.
    #
    #    # Using a Hash
    #    Post.where_assoc_exists(:comments, spam_flag: true)
    #
    #    # Using a String
    #    Post.where_assoc_exists(:comments, "spam_flag = true")
    #
    #    # Using an Array (a string and its binds)
    #    Post.where_assoc_exists(:comments, ["spam_flag = ?", true])
    #
    # If the second argument is blank-ish, it is ignored (as #where does).
    def self.where_assoc_exists(base_relation, association_name, given_scope = nil, &block)
      base_relation, nested_relation = relation_on_association(base_relation, association_name, given_scope, block, NestWithExistsBlock)
      NestWithExistsBlock.call(base_relation, nested_relation)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model doesn't exist.
    #
    # See #where_assoc_exists for usage details. The only difference is that a record
    # is matched if no matching association record is found.
    def self.where_assoc_not_exists(base_relation, association_name, given_scope = nil, &block)
      base_relation, nested_relation = relation_on_association(base_relation, association_name, given_scope, block, NestWithExistsBlock)
      NestWithExistsBlock.call(base_relation, nested_relation, "NOT ")
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on how many records for the specified association of the model exists. Conditions
    # the associated model must match can also be specified.
    #
    # #where_assoc_count is a generalization of #where_assoc_exists, allowing you to
    # for example, filter for comments that have at least 2 matching posts
    def self.where_assoc_count(base_relation, left_operand, operator, association_name, given_scope = nil, &block)
      deepest_scope_mod = lambda do |deepest_scope|
        deepest_scope = apply_proc_scope(deepest_scope, block) if block

        deepest_scope.unscope(:select).select("COUNT(*)")
      end

      base_relation, nested_relation = relation_on_association(base_relation, association_name, given_scope, deepest_scope_mod, NestWithSumBlock)
      operator = case operator.to_s
                 when "=="
                   "="
                 when "!="
                   "<>"
                 else
                   operator
                 end

      base_relation.where("(#{left_operand}) #{operator} COALESCE((#{nested_relation.to_sql}), 0)")
    end

    # Returns the receiver (with possible alterations) and a relation meant to be embed in the received.
    # association_names_path: can be an array of association names or a single one
    def self.relation_on_association(base_relation, association_names_path, given_scope = nil, last_assoc_block = nil, nest_assocs_block = nil)
      association_names_path = Array.wrap(association_names_path)

      if association_names_path.size > 1
        recursive_scope_block = lambda do |scope|
          scope, nested_scope = relation_on_association(scope, association_names_path[1..-1], given_scope, last_assoc_block, nest_assocs_block)
          nest_assocs_block.call(scope, nested_scope)
        end

        relation_on_one_association(base_relation, association_names_path.first, nil, recursive_scope_block, nest_assocs_block)
      else
        relation_on_one_association(base_relation, association_names_path.first, given_scope, last_assoc_block, nest_assocs_block)
      end
    end

    # Returns the receiver (with possible alterations) and a relation meant to be embed in the received.
    def self.relation_on_one_association(base_relation, association_name, given_scope = nil, last_assoc_block = nil, nest_assocs_block = nil)
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
        skip_next = true if has_and_belongs_to_many?(reflection)

        current_scope = initial_scope_from_reflection(reflection_chain[i..-1], constaints_chain[i])

        current_scope = process_association_step_limits(current_scope, reflection, relation_klass)

        if i.zero?
          current_scope = current_scope.where(given_scope) if given_scope
          current_scope = apply_proc_scope(current_scope, last_assoc_block) if last_assoc_block
        end

        # Those make no sense since we are only limiting the value that would match, using conditions
        current_scope = current_scope.unscope(:limit, :order, :offset)
        current_scope = nest_assocs_block.call(current_scope, nested_scope) if nested_scope

        nested_scope = current_scope
      end

      [base_relation, current_scope]
    end

    def self.fetch_reflection(relation_klass, association_name)
      association_name = ActiveRecordCompat.normalize_association_name(association_name)
      reflection = relation_klass._reflections[association_name]

      if reflection.nil?
        # Need to use build because this exception expects a record...
        raise ActiveRecord::AssociationNotFoundError.new(relation_klass.new, association_name)
      end
      if reflection.macro == :belongs_to && reflection.options[:polymorphic]
        # TODO: We might want an option to indicate that using pluck is ok?
        raise NotImplementedError, "Can't deal with polymorphic belongs_to"
      end

      reflection
    end

    def self.initial_scope_from_reflection(reflection_chain, constraints)
      reflection = reflection_chain.first
      current_scope = reflection.klass.default_scoped

      if has_and_belongs_to_many?(reflection)
        # has_and_belongs_to_many, behind the scene has a secret model and uses a has_many through.
        # This is the first of those two secret has_many through.
        #
        # In order to handle limit, offset, order correctly on has_and_belongs_to_man,
        # we must do both this reflection and the next one at the same time.
        # Think of it this way, if you have limit 3:
        #   Apply only on 1st step: You check that any of 2nd step for the first 3 of 1st step match
        #   Apply only on 2nd step: You check that any of the first 3 of second step match for any 1st step
        #   Apply over both (as we do): You check that only the first 3 of doing both step match,

        # To create the join, simply using next_reflection.klass.default_scoped.joins(reflection.name)
        # would be great, except we cannot add a given_scope afterward because we are on the wrong "base class",
        # and we can't do #merge because of the LEW crap.
        # So we must do the joins ourself!
        sub_join_contraints = join_constraints(reflection)
        next_reflection = reflection_chain[1]

        current_scope = current_scope.joins(<<-SQL)
            INNER JOIN #{next_reflection.klass.quoted_table_name} ON #{sub_join_contraints.to_sql}
        SQL

        join_constaints = join_constraints(next_reflection)
      else
        join_constaints = join_constraints(reflection)
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

      current_scope.where(join_constaints)
    end

    def self.constraint_allowed_lim_off_from(reflection)
      if has_and_belongs_to_many?(reflection)
        reflection.scope
      else
        # For :through associations, it's pretty hard/tricky to apply limit/offset/order of the
        # whole has_* :through. For now, we only do the direct associations from one model to another
        # that the :through uses and we ignore the limit from the scope of has_* :through.
        #
        # For :through associations, #actual_source_reflection returns final non-through
        # reflection that is reached by following the :source.
        # Otherwise, returns itself.
        reflection.send(:actual_source_reflection).scope
      end
    end

    def self.process_association_step_limits(current_scope, reflection, relation_klass)
      return current_scope.unscope(:limit, :offset, :order) if reflection.macro == :belongs_to

      current_scope = current_scope.limit(1) if reflection.macro == :has_one

      # Order is useless without either limit or offset
      current_scope = current_scope.unscope(:order) if !current_scope.limit_value && !current_scope.offset_value

      return current_scope unless current_scope.limit_value || current_scope.offset_value
      if %w(mysql mysql2).include?(relation_klass.connection.adapter_name.downcase)
        raise MySQLIsTerribleError, "Associations/default_scopes with a limit are not supported for MySQL"
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

      if reflection.klass.table_name.include?(".")
        # This works universally, but seems to sometimes have slower performances.. Need to test if there is an alternative way
        # of expressing this...
        # TODO: Investigate a way to improve performances, or maybe require a flag to do it this way?
        # We use unscoped to avoid duplicating the conditions in the query, which is noise. (unless if it
        # could helps the query planner of the DB, if someone can show it to be worth it, then this can be changed.)

        reflection.klass.unscoped.where(id: current_scope)
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

    def self.join_constraints(reflection)
      join_keys = ActiveRecordCompat.join_keys(reflection)

      key = join_keys.key
      foreign_key = join_keys.foreign_key

      table = reflection.klass.arel_table
      foreign_klass = reflection.send(:actual_source_reflection).active_record
      foreign_table = foreign_klass.arel_table

      # Using default_scope / unscoped / any scope comes with the STI constrain built-in for free!

      constraints = table[key].eq(foreign_table[foreign_key])

      if reflection.type
        # Handing of the polymorphic has_many/has_one's type column
        constraints = constraints.and(table[reflection.type].eq(foreign_klass.name))
      end
      constraints
    end

    def self.has_and_belongs_to_many?(reflection) # rubocop:disable Naming/PredicateName
      parent = ActiveRecordCompat.parent_reflection(reflection)
      parent && parent.macro == :has_and_belongs_to_many
    end
  end
end
