# frozen_string_literal: true

module ActiveRecordWhereAssoc
  module Helpers
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
      def self.chained_reflection_and_chained_constraints(reflection)
        reflection.chain.map { |ref| [ref, ref.constraints] }.transpose
      end
    else
      def self.chained_reflection_and_chained_constraints(reflection)
        [reflection.chain, reflection.scope_chain]
      end
    end

    def self.has_and_belongs_to_many?(reflection)
      parent = parent_reflection(reflection)
      parent && parent.macro == :has_and_belongs_to_many
    end

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      def self.parent_reflection(reflection)
        reflection.parent_reflection
      end
    else
      def self.parent_reflection(reflection)
        _parent_name, parent_refl = reflection.parent_reflection
        parent_refl
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
