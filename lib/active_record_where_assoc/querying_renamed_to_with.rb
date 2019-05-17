# frozen_string_literal: true

# Needed for delegate
require "active_support"

module ActiveRecordWhereAssoc
  module QueryingRenamedToWith
    new_query_methods = QueryMethodsRenamedToWith.public_instance_methods
    delegate(*new_query_methods, to: :all)
  end
end
