# frozen_string_literal: true

module ActiveRecordWhereAssoc
  module Helpers
    # Apply a condition to a scope, possibly by sending a symbol
    # Receiving:
    # * a Hash, String or Array will pass them to unscoped.where
    # * a symbol passes it to unscoped.send
    # * otherwise raises an exception
    def self.apply_scope(relation, scope)
      case scope
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
