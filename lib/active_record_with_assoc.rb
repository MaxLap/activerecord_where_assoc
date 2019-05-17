# frozen_string_literal: true

# Load the gem and the default set of names
require_relative "active_record_where_assoc"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.include(ActiveRecordWhereAssoc::QueryMethodsRenamedToWith)
  ActiveRecord::Base.extend(ActiveRecordWhereAssoc::QueryingRenamedToWith)
end
