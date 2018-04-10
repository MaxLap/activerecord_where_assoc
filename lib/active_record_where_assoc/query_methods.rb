# frozen_string_literal: true

require_relative "active_record_compat"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module QueryMethods
    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model exists. Conditions
    # the associated model must match to count as existing can also be specified.
    #
    # Here is a quick overview of the arguments received followed by a detailed explanation
    # along with more examples. You may also consider viewing the gem's README, packaged
    # with the gem and easily viewable on github:
    # https://github.com/MaxLap/activerecord_where_assoc
    #
    # As 1st argument, you must specify the association to check against. This can be
    # any of the associations on the current relation's model.
    #
    #    # Posts that have at least one comment
    #    Post.where_assoc_exists(:comments)
    #
    # As 2nd argument, you can add conditions that the records in the association must match
    # to be considered as existing.
    #
    # The 3rd argument is for options that alter how the query is generated.
    #
    # If your conditions are too complex or too long to be placed in the 2nd argument,
    # #where_assoc_* accepts a block in which you can do anything you want on the relation
    # (any scoping method such as #where, #joins, nested #where_assoc_*).
    #
    # === the condition argument (2nd argument)
    #
    # This argument is additional conditions the association's records must fulfill to be
    # considered as "existing". The argument is passed directly to #where.
    #
    #    # Posts that have at least one comment considered as spam
    #    # Using a Hash
    #    Post.where_assoc_exists(:comments, spam_flag: true)
    #
    #    # Using a String
    #    Post.where_assoc_exists(:comments, "spam_flag = true")
    #
    #    # Using an Array (a string and its binds)
    #    Post.where_assoc_exists(:comments, ["spam_flag = ?", true])
    #
    # If the condition argument is blank, it is ignored (just like #where does).
    #
    # === the options argument (3rd argument)
    #
    # Some options are available to tweak how things queries are generated. In some case, this
    # also changes the results of the query.
    #
    # ignore_limit: when true, #limit and #offset that are set either from default_scope or
    #               on associations are ignored. #has_one means #limit(1), so this makes
    #               #has_one be treated like #has_many.
    #
    # never_alias_limit: when true, #where_assoc_* will not use #from to build relations that
    #                    have #limit or #offset set on default_scope or on associations.
    #                    Note, #has_one means #limit(1), so it will also use #from unless this
    #                    option is activated.
    #
    # === the block
    #
    # The block is used to add more complex conditions. The result behaves the same way
    # as the 2nd argument's conditions, but lets you do things such as #where, #joins,
    # nested #where_assoc_*. Note that using #joins might lead to unexpected results when
    # using where_assoc_count, since if the join changes the number of rows, it will change
    # the resulting count.
    #
    # There are 2 ways of using the block for adding conditions to the association.
    #
    # * A block that receives one argument
    # The block receives a relation on the target association and return a relation with added
    # filters or may return nil to do nothing.
    #
    #    # Using a where for the added condition
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(spam_flag: true) }
    #
    #    # Applying a scope of the relation
    #    Post.where_assoc_exists(:comments) { |comments| comments.spam_flagged }
    #
    #    # Applying a scope of the relation, using the &:shortcut for procs
    #    Post.where_assoc_exists(:comments, &:spam_flagged)
    #
    #
    # * A block that receives no argument
    # Instead of receiving the relation as argument, the relation is used as the "self" of
    # the block. Everything else is identical to the block with one argument.
    #
    #    # Using a where for the added condition
    #    Post.where_assoc_exists(:comments) { where(spam_flag: true) }
    #
    #    # Applying a scope of the relation
    #    Post.where_assoc_exists(:comments) { spam_flagged }
    #
    # The main reason not to use this and use a block with an argument is when you need to
    # call methods on the real self around of the block, such as:
    #
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(id: self.something) }
    #
    def where_assoc_exists(association_name, given_scope = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_exists(self, association_name, given_scope, options, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model doesn't exist.
    #
    # The parameters and everything is identical to #where_assoc_exists. The only
    # difference is that a record is matched if no matching association record that
    # fulfill the conditions are found.
    def where_assoc_not_exists(association_name, given_scope = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_not_exists(self, association_name, given_scope, options, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on how many records for the specified association of the model exists. Conditions
    # the associated model must match can also be specified.
    #
    # #where_assoc_count is a generalization of #where_assoc_exists and #where_assoc_not_exists.
    # It behave behaves the same way as them, but is more flexible as it allows you to be
    # specific about how many match there should be. To clarify, here are equivalent examples:
    #
    #    Post.where_assoc_exists(:comments)
    #    Post.where_assoc_count(1, :<=, :comments)
    #
    #    Post.where_assoc_not_exists(:comments)
    #    Post.where_assoc_count(0, :==, :comments)
    #
    # The usage is the same as with #where_assoc_exists, however, 2 arguments are inserted
    # at the beginning.
    #
    # 1st argument: a number or any string of SQL to embed in the SQL that returns a number
    #               that can be used for the comparison.
    # 2nd argument: the operator to use: `:<`, `:<=`, `:==`, `:>=`, `:>`
    # 3rd, 4th and 5th arguments: same as #where_assoc_exists' 1st, 2nd and 3rd arguments
    # block: same as #where_assoc_exists' block
    #
    # The order of the parameters may seem confusing. But you will get used to it. To help
    # remember the order of the parameters, remember that the goal is to do:
    #    5 < (SELECT COUNT(*) FROM ...)
    # So the parameters are in the same order as in that query: number, operator, association.
    def where_assoc_count(left_operand, operator, association_name, given_scope = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_count(self, left_operand, operator, association_name, given_scope, options, &block)
    end
  end
end
