# frozen_string_literal: true

# Needed for delegate
require "active_support"

module ActiveRecordWhereAssoc
  module RelationReturningDelegates
    # Delegating the methods in RelationReturningMethods from ActiveRecord::Base to :all. Same thing ActiveRecord does for #where.
    new_relation_returning_methods = RelationReturningMethods.public_instance_methods
    delegate(*new_relation_returning_methods, to: :all)
  end
end
