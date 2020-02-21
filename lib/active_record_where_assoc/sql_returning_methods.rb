# frozen_string_literal: true

module ActiveRecordWhereAssoc
  # The methods in this module return partial SQL queries. These are used by the main methods of
  # this gem: the #where_assoc_* methods located in QueryMethods. But in some situation, the SQL strings can be useful to
  # do complex manual queries by embedding them in your own SQL code.
  #
  # Those methods should be used directly on your model's class. You can use them from a relation, but the result will be
  # the same, so your intent will be clearer by doing it on the class directly.
  #
  #   # This is the recommended way:
  #   sql = User.assoc_exists_sql(:posts)
  #
  #   # While this also works, it may be confusing when reading the code:
  #   sql = my_filtered_users.assoc_exists_sql(:posts)
  #   # the sql variable is not affected by my_filtered_users.
  module SqlReturningMethods
    # This method returns a string containing the SQL condition used by QueryMethods#where_assoc_exists.
    # You can pass that SQL string directly to #where to get the same result as QueryMethods#where_assoc_exists.
    # This can be useful to get the SQL of an EXISTS query for use in your own SQL code.
    #
    # For example:
    #   # Users with a post or a comment
    #   User.where("#{User.assoc_exists_sql(:posts)} OR #{User.assoc_exists_sql(:comments)}")
    #   my_users.where("#{User.assoc_exists_sql(:posts)} OR #{User.assoc_exists_sql(:comments)}")
    #
    # The parameters are the same as QueryMethods#where_assoc_exists, including the
    # possibility of specifying a list of association_name.
    def assoc_exists_sql(association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.assoc_exists_sql(self, association_name, conditions, options, &block)
    end

    # This method generates the SQL query used by QueryMethods#where_assoc_not_exists.
    # This method is the same as #assoc_exists_sql, but for QueryMethods##where_assoc_not_exists.
    #
    # The parameters are the same as QueryMethods#where_assoc_not_exists, including the
    # possibility of specifying a list of association_name.
    def assoc_not_exists_sql(association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.assoc_not_exists_sql(self, association_name, conditions, options, &block)
    end

    # This method returns a string containing the SQL condition used by QueryMethods#where_assoc_count.
    # You can pass that SQL string directly to #where to get the same result as QueryMethods#where_assoc_count.
    # This can be useful to get the SQL query to compare the count of an association for use in your own SQL code.
    #
    # For example:
    #   # Users with at least 10 posts or at least 10 comment
    #   User.where("#{User.compare_assoc_count_sql(10, :<=, :posts)} OR #{User.compare_assoc_count_sql(10, :<=, :comments)}")
    #   my_users.where("#{User.compare_assoc_count_sql(10, :<=, :posts)} OR #{User.compare_assoc_count_sql(10, :<=, :comments)}")
    #
    # The parameters are the same as QueryMethods#where_assoc_count, including the
    # possibility of specifying a list of association_name.
    def compare_assoc_count_sql(left_operand, operator, association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.compare_assoc_count_sql(self, left_operand, operator, association_name, conditions, options, &block)
    end

    # This method returns a string containing the SQL to count an association used by QueryMethods#where_assoc_count.
    # The returned SQL does not do a comparison, only the counting part. So you can do the comparison yourself.
    # This can be useful to get the SQL to count the an association query for use in your own SQL code.
    #
    # For example:
    #   # Users with more posts than comments
    #   User.where("#{User.only_assoc_count_sql(:posts)} > #{User.only_assoc_count_sql(:comments)}")
    #   my_users.where("#{User.only_assoc_count_sql(:posts)} > #{User.only_assoc_count_sql(:comments)}")
    #
    # Since the comparison is not made by this method, the first 2 parameters (left_operand and operator)
    # of QueryMethods#where_assoc_count are not accepted by this method. The remaining
    # parameters of QueryMethods#where_assoc_count are accepted, which are the same
    # the same as those of QueryMethods#where_assoc_exists.
    def only_assoc_count_sql(association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.only_assoc_count_sql(self, association_name, conditions, options, &block)
    end
  end
end
