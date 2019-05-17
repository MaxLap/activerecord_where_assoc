# frozen_string_literal: true

module ActiveRecordWhereAssoc
  # This module is simply an alternative set of methods names to use instead of the default.
  # New method names <= default method names
  #
  # with_assoc <= where_assoc_exists
  # without_assoc <= where_assoc_not_exists
  # with_assoc_count <= where_assoc_count
  #
  # While shorter, this set of names feels like it loses some of its meaning and may be easier
  # to confound with other features of ActiveRecord, such as eager_loading.
  #
  # The word "where" in the default method names makes it much ore clear that this is just
  # another condition on the model.
  module QueryMethodsRenamedToWith
    # :section: Basic methods

    # See QueryMethods#where_assoc_exists
    def with_assoc(association_name, conditions = nil, options = {}, &block)
      where_assoc_exists(association_name, conditions, options, &block)
    end

    # See QueryMethods#where_assoc_not_exists
    def without_assoc(association_name, conditions = nil, options = {}, &block)
      where_assoc_not_exists(association_name, conditions, options, &block)
    end

    # :section: Complex method

    # See QueryMethods#where_assoc_count
    def with_assoc_count(left_operand, operator, association_name, conditions = nil, options = {}, &block)
      where_assoc_count(left_operand, operator, association_name, conditions, options, &block)
    end
  end
end
