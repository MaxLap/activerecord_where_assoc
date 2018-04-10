# frozen_string_literal: true

require "active_record_where_assoc/version"
require "active_record"

module ActiveRecordWhereAssoc
  # Default options for the gem. Meant to be modified in place by external code
  def self.default_options
    @default_options ||= {
                           ignore_limit: false,
                           never_alias_limit: false,
                         }
  end
end

require "active_record_where_assoc/core_logic"
require "active_record_where_assoc/query_methods"
require "active_record_where_assoc/querying"

ActiveSupport.on_load(:active_record) do
  ActiveRecord.eager_load!

  # Need to use #send for the include to support Ruby 2.0
  ActiveRecord::Relation.send(:include, ActiveRecordWhereAssoc::QueryMethods)
  ActiveRecord::Base.extend(ActiveRecordWhereAssoc::Querying)
end
