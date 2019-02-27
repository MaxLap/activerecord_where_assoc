# frozen_string_literal: true

require_relative "active_record_where_assoc/version"
require "active_record"

module ActiveRecordWhereAssoc
  # Default options for the gem. Meant to be modified in place by external code, such as in
  # an initializer.
  # Ex:
  #   ActiveRecordWhereAssoc[:ignore_limit] = true
  #
  # A description for each can be found in ActiveRecordWhereAssoc::QueryMethods#where_assoc_exists.
  #
  # The only one that truly makes sense to change is :ignore_limit, when you are using MySQL, since
  # limit are never supported on it.
  def self.default_options
    @default_options ||= {
                           ignore_limit: false,
                           never_alias_limit: false,
                           poly_belongs_to: :raise,
                         }
  end
end

require_relative "active_record_where_assoc/core_logic"
require_relative "active_record_where_assoc/query_methods"
require_relative "active_record_where_assoc/querying"

ActiveSupport.on_load(:active_record) do
  ActiveRecord.eager_load!

  # Need to use #send for the include to support Ruby 2.0
  ActiveRecord::Relation.send(:include, ActiveRecordWhereAssoc::QueryMethods)
  ActiveRecord::Base.extend(ActiveRecordWhereAssoc::Querying)
end
