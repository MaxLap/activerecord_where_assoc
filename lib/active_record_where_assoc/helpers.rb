
# frozen_string_literal: true

module ActiveRecordWhereAssoc
  module Helpers
    # A simpler way for some tools that want to receive relations to cast parameters to relations.
    # Receiving:
    # * a relation just returns it
    # * a Hash, String or Array will pass them to unscoped.where
    # * a symbol passes it to unscoped.send
    # * otherwise raises an exception
    def self.unscoped_relation_from(model, arg)
      if arg.is_a?(ActiveRecord::Relation)
        arg
      elsif arg.is_any?(Hash, String, Array, Arel::Node)
        model.unscoped.where(arg)
      elsif arg.is_a?(Symbol)
        model.unscoped.send(arg)
      else
        raise ArgumentError, "Unhandled argument of type '#{relation.type.name}' received"
      end
    end

    # Apply a where on a nested scope using Arel::Nodes instead of turning everything to a string.
    def self.where_on_nested_scope(scope, nested_scope, &block)
      ast = nested_scope.ast
      ast = yield ast if block_given?

      result = scope.where(ast)
      # Using an Arel::Node in #where doesn't allow passing the matching binds, so we do it by hand...
      result.where_clause.binds.concat(nested_scope.where_clause.binds)
      result
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
