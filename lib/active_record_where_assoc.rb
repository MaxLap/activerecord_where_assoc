# frozen_string_literal: true

require "active_record_where_assoc/version"
require "active_record"

require "active_record_where_assoc/query_methods"
require "active_record_where_assoc/querying"

ActiveSupport.on_load(:active_record) do
  ActiveRecord.eager_load!

  ActiveRecord::Relation.include(ActiveRecordWhereAssoc::QueryMethods)
  ActiveRecord::Base.extend(ActiveRecordWhereAssoc::Querying)
end
