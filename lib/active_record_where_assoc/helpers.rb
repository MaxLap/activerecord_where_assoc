
# frozen_string_literal: true

module ActiveRecordWhereAssoc
  module Helpers
    # A simpler way for some tools that want to receive relations to cast parameters to relations.
    # Receiving:
    # * a relation just returns it
    # * a Hash, String or Array will pass them to unscoped.where
    # * a symbol passes it to unscoped.send
    # * otherwise raises an exception
    def self.apply_scope(relation, scope)
      case scope
      when ActiveRecord::Relation
        relation.merge(scope)
      when Hash, String, Array, Arel::Node
        relation.where(scope)
      when Symbol
        relation.send(scope)
      else
        raise ArgumentError, "Unhandled argument of type '#{scope.class.name}' received"
      end
    end

    if ActiveRecord.gem_version >= Gem::Version.new("5.1")
      def self.join_keys(reflection)
        reflection.join_keys
      end
    elsif ActiveRecord.gem_version >= Gem::Version.new("5.0")
      def self.join_keys(reflection)
        reflection.join_keys(reflection.klass)
      end
    end
  end
end
