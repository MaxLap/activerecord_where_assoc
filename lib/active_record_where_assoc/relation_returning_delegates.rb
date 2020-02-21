# frozen_string_literal: true

# Needed for delegate
require "active_support"

module ActiveRecordWhereAssoc
  module RelationReturningDelegates
    # Delegating the methods in QueryMethods from ActiveRecord::Base to :all. Same thing ActiveRecord does for #where.
    new_query_methods = QueryMethods.public_instance_methods
    delegate(*new_query_methods, to: :all)
  end
end
