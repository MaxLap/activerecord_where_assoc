# frozen_string_literal: true

module ActiveRecordWhereAssoc
  module ActiveRecordCompat
    if ActiveRecord.gem_version >= Gem::Version.new("6.1.0.rc1")
      JoinKeys = Struct.new(:key, :foreign_key)
      def self.join_keys(reflection, poly_belongs_to_klass)
        if poly_belongs_to_klass
          JoinKeys.new(reflection.join_primary_key(poly_belongs_to_klass), reflection.join_foreign_key)
        else
          JoinKeys.new(reflection.join_primary_key, reflection.join_foreign_key)
        end
      end

    elsif ActiveRecord.gem_version >= Gem::Version.new("5.1")
      def self.join_keys(reflection, poly_belongs_to_klass)
        if poly_belongs_to_klass
          reflection.get_join_keys(poly_belongs_to_klass)
        else
          reflection.join_keys
        end
      end
    elsif ActiveRecord.gem_version >= Gem::Version.new("4.2")
      def self.join_keys(reflection, poly_belongs_to_klass)
        reflection.join_keys(poly_belongs_to_klass || reflection.klass)
      end
    else
      # 4.1 change that introduced JoinKeys:
      # https://github.com/rails/rails/commit/5823e429981dc74f8f53187d2ab573823381bf28#diff-523caff658498027f61cae9d91c8503dL108
      JoinKeys = Struct.new(:key, :foreign_key)
      def self.join_keys(reflection, poly_belongs_to_klass)
        if reflection.source_macro == :belongs_to
          key = reflection.association_primary_key(poly_belongs_to_klass)
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
        pairs = reflection.chain.map do |ref|
          # PolymorphicReflection is a super weird thing. Like a partial reflection, I don't get it.
          # Seems like just bypassing it works for our needs.
          # When doing a has_many through that has a polymorphic source and a source_type, this ends up
          # part of the chain instead of the regular HasManyReflection that one would expect.
          ref = ref.instance_variable_get(:@reflection) if ref.is_a?(ActiveRecord::Reflection::PolymorphicReflection)

          [ref, ref.constraints]
        end

        pairs.transpose
      end
    else
      def self.chained_reflection_and_chained_constraints(reflection)
        [reflection.chain, reflection.scope_chain]
      end
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

    if ActiveRecord.gem_version >= Gem::Version.new("5.0")
      def self.through_reflection?(reflection)
        reflection.through_reflection?
      end
    else
      def self.through_reflection?(reflection)
        reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
      end
    end

    if ActiveRecord.gem_version >= Gem::Version.new("7.1.0.alpha")
      def self.null_relation?(reflection)
        reflection.null_relation?
      end
    else
      def self.null_relation?(reflection)
        reflection.is_a?(ActiveRecord::NullRelation)
      end
    end
  end
end
