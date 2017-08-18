# frozen_string_literal: true

module ActiveRecordWhereAssoc
  module Helpers
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

    def self.join_constraints(reflection, next_reflection, final_klass)
      join_keys = Helpers.join_keys(reflection)
      key = join_keys.key
      foreign_key = join_keys.foreign_key

      table = reflection.klass.arel_table
      foreign_klass = next_reflection ? next_reflection.klass : final_klass
      foreign_table = foreign_klass.arel_table

      # Using default_scope / unscoped / any scope comes with the STI constrain built-in for free!

      constraints = table[key].eq(foreign_table[foreign_key])

      if reflection.type
        # Handing of the polymorphic has_many/has_one's type column
        constraints = constraints.and(table[reflection.type].eq(foreign_klass.name))
      end
      constraints
    end

    if ActiveRecord.gem_version >= Gem::Version.new("5.1")
      def self.join_keys(reflection)
        reflection.join_keys
      end
    elsif ActiveRecord.gem_version >= Gem::Version.new("4.2")
      def self.join_keys(reflection)
        reflection.join_keys(reflection.klass)
      end
    else
      # 4.1 change that introduced JoinKeys:
      # https://github.com/rails/rails/commit/5823e429981dc74f8f53187d2ab573823381bf28#diff-523caff658498027f61cae9d91c8503dL108
      JoinKeys = Struct.new(:key, :foreign_key)
      def self.join_keys(reflection)
        if reflection.source_macro == :belongs_to
          # The original code had to handle polymorphic here. But we don't support polymorphic belongs_to
          # So the code would never reach here in the polymorphic case.
          key = reflection.association_primary_key
          foreign_key = reflection.foreign_key
        else
          key         = reflection.foreign_key
          foreign_key = reflection.active_record_primary_key
        end

        JoinKeys.new(key, foreign_key)
      end
    end

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      def self.chain_reflection_and_constraints(reflection)
        reflection.chain.map { |ref| [ref, ref.constraints] }
      end
    else
      def self.chain_reflection_and_constraints(reflection)
        reflection.chain.zip(reflection.scope_chain)
      end
    end

    if ActiveRecord.gem_version >= Gem::Version.new("4.2")
      def self.normalize_association_name(association_name)
        association_name.to_s
      end
    else
      def self.normalize_association_name(association_name)
        association_name.to_sym
      end
    end
  end
end
