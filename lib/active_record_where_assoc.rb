# frozen_string_literal: true

require_relative "active_record_where_assoc/version"
require "active_record"

module ActiveRecordWhereAssoc
  # Default options for the gem. Meant to be modified in place by external code, such as in
  # an initializer.
  # Ex:
  #   ActiveRecordWhereAssoc.default_options[:ignore_limit] = true
  #
  # A description for each can be found in RelationReturningMethods@Options.
  #
  # :ignore_limit is the only one to consider changing, when you are using MySQL, since limit are
  # never supported on it. Otherwise, the safety of having to pass the options yourself
  # and noticing you made a mistake / avoiding the need for extra queries is worth the extra code.
  def self.default_options
    @default_options ||= {
                           ignore_limit: false,
                           never_alias_limit: false,
                           poly_belongs_to: :raise,
                         }
  end
end

require_relative "active_record_where_assoc/core_logic"
require_relative "active_record_where_assoc/relation_returning_methods"
require_relative "active_record_where_assoc/relation_returning_delegates"
require_relative "active_record_where_assoc/sql_returning_methods"

ActiveSupport.on_load(:active_record) do
  ActiveRecord.eager_load!

  ActiveRecord::Relation.include(ActiveRecordWhereAssoc::RelationReturningMethods)
  ActiveRecord::Base.extend(ActiveRecordWhereAssoc::RelationReturningDelegates)
  ActiveRecord::Base.extend(ActiveRecordWhereAssoc::SqlReturningMethods)
end
