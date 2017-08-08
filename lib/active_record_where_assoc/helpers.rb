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
