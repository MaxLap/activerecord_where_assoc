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
    # along with more examples. You may also consider viewing the gem's README. It contains
    # known issues and some tips. The readme is packaged with the gem and viewable on github:
    # https://github.com/MaxLap/activerecord_where_assoc
    #
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
    # (any scoping method such as #where, #joins, nested #where_assoc_*, scopes of the model).
    #
    # === the association argument (1st argument)
    #
    # This is the association you want to check if records exists. If you want, you can pass
    # an array of associations. They will be followed in order, just like a has_many :through
    # would.
    #
    #    # Posts with at least one comment
    #    Post.where_assoc_exists(:comments)
    #
    #    # Posts for which there is at least one reply to a comment.
    #    Post.where_assoc_exists([:comments, :replies])
    #
    # Note that if you use conditions / blocks, they will only be applied to the last
    # association of the array. If you want something else, you will need to use
    # the block argument to nest multiple calls to #where_assoc_exists
    #
    #    # Post.where_assoc_exists(:comments) { where_assoc_exists(:replies) }
    #
    # === the condition argument (2nd argument)
    #
    # This argument is additional conditions the association's records must fulfill to be
    # considered as "existing". The argument is passed directly to #where.
    #
    #    # Posts that have at least one comment considered as spam
    #    # Using a Hash
    #    Post.where_assoc_exists(:comments, is_spam: true)
    #
    #    # Using a String
    #    Post.where_assoc_exists(:comments, "is_spam = true")
    #
    #    # Using an Array (a string and its binds)
    #    Post.where_assoc_exists(:comments, ["is_spam = ?", true])
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
    # poly_belongs_to: Allows to specify what to do when a polymorphic belongs_to is
    #                  encountered. Things are tricky because the query can end up searching
    #                  in multiple Models, and just knowing which ones to look into can
    #                  require an expensive query. It's also possible that you only want to
    #                  search for those that match some specific Models, ignoring the other ones.
    #                  Can be:
    #                  * :pluck to do a pluck in the column to detect to possible choices.
    #                    this option can have a performance cost for big tables
    #                  * a model or an array of model to specify which models to consider.
    #                    This avoids the performance cost of pluck, and can allow to filter
    #                    some of the choices out that don't interest you. Note, this is not
    #                    instances, it's actual models, ex: [Post, Comment]
    #                  * a Hash to do the same as Array, placing the models in the keys of the Hash,
    #                    but this also allows to apply specific conditions for the model.
    #                    The conditions are either a proc (behaves like the block) or the same thing
    #                    #where accepts (String, Hash, Array, nil). Ex:
    #                      List.where_assoc_exists(:items,
    #                                              nil,
    #                                              poly_belongs_to: {Car => "color = blue",
    #                                                                Computer => proc { brand_new.where(core: 4) } })
    #                  * :raise to raise an exception when this happens. This is the default
    #
    # === the block
    #
    # The block is used to add more complex conditions. The result behaves the same way
    # as the 2nd argument's conditions, but lets you use any scoping methods, such as
    # #where, #joins, # nested #where_assoc_* and scopes of the model. Note that using
    # #joins might lead to unexpected results when using #where_assoc_count, since if
    # the joins adds rows, it will change the resulting count.
    #
    # There are 2 ways of using the block for adding conditions to the association.
    #
    # * A block that receives one argument
    # The block receives a relation on the target association and return a relation with added
    # filters or may return nil to do nothing.
    #
    #    # Using a where for the added condition
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(is_spam: true) }
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
    #    Post.where_assoc_exists(:comments) { where(is_spam: true) }
    #
    #    # Applying a scope of the relation
    #    Post.where_assoc_exists(:comments) { spam_flagged }
    #
    # The main reason to use a block with an argument instead of without is when you need
    # to call methods on the self outside of the block, such as:
    #
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(id: self.something) }
    #
    def where_assoc_exists(association_name, given_scope = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_exists(self, association_name, given_scope, options, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model doesn't exist.
    # Conditions the associated model must match to count as existing can also be specified.
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
    # specific about how many matches there should be. To clarify, here are equivalent examples:
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
    # 1st argument: the left side of the comparison. One of:
    #               a number
    #               a string of SQL to embed in the query
    #               a range (operator must be :== or :!=), will use BETWEEN or NOT BETWEEN
    #                                                      supports infinite ranges and exclusive end
    # 2nd argument: the operator to use: :<, :<=, :==, :!=, :>=, :>
    # 3rd, 4th and 5th arguments: same as #where_assoc_exists' 1st, 2nd and 3rd arguments
    # block: same as #where_assoc_exists' block
    #
    # The order of the parameters may seem confusing. But you will get used to it. To help
    # remember the order of the parameters, remember that the goal is to do:
    #    5 < (SELECT COUNT(*) FROM ...)
    # So the parameters are in the same order as in that query: number, operator, association.
    #
    # To be clear, when you use multiple associations in an array, the count you will be
    # comparing against is the total number of records of that last association.
    #
    #   # The users that have received at least 5 comments total on all of their posts
    #   # So this can be one post that has 5 comments of 5 posts with 1 comments
    #   User.where_assoc_count(5, :<=, [:posts, :comments])
    #
    #   # The users that have at least 5 posts with at least one comments
    #   User.where_assoc_count(5, :<=, :posts) { where_assoc_exists(:comments) }
    def where_assoc_count(left_operand, operator, association_name, given_scope = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_count(self, left_operand, operator, association_name, given_scope, options, &block)
    end
  end
end
