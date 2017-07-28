# frozen_string_literal: true

# Needed for delegate
require "active_support"

module ActiveRecordWhereAssoc
  module Querying
    new_query_methods = QueryMethods.public_instance_methods
    delegate(*new_query_methods, to: :all)
  end
end
