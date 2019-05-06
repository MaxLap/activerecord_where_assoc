# frozen_string_literal: true

require_relative "active_record_compat"
require_relative "exceptions"

# See ActiveRecordWhereAssoc::QueryMethods
module ActiveRecordWhereAssoc
  module QueryMethods
    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model exists. Conditions
    # the associated model must match can can also be specified.
    #
    # Quick overview of arguments, more details after:
    # * <b>association_name</b>: The association to check against
    # * <b>condition</b>: Filtering the associated record must match
    # * <b>options</b>: Options to alter the generated query
    # * <b>&block</b>: More complex filtering the associated record must match
    #
    # You may also consider viewing the gem's README. It contains
    # known issues and some tips. You can view the
    # {README on github}[https://github.com/MaxLap/activerecord_where_assoc/blob/master/README.md].
    #
    # [association_name]
    #   This is the association you want to check if records exists. If you want, you can pass
    #   an array of associations. They will be followed in order, just like a has_many :through
    #   would.
    #
    #      # Posts with at least one comment
    #      Post.where_assoc_exists(:comments)
    #
    #      # Posts for which there is at least one reply to a comment.
    #      Post.where_assoc_exists([:comments, :replies])
    #
    #   Note that if you use conditions / blocks, they will only be applied to the last
    #   association of the array. If you want something else, you will need to use
    #   the block argument to nest multiple calls to #where_assoc_exists
    #
    #      # Posts with a flagged comment that has a reply
    #      Post.where_assoc_exists(:comments) {
    #        where(flagged: true).where_assoc_exists(:replies)
    #      }
    #
    # [condition]
    #   This argument is additional conditions the association's records must fulfill to be
    #   considered as "existing". The argument is passed directly to +#where+.
    #
    #      # Posts that have at least one comment considered as spam
    #      # Using a Hash
    #      Post.where_assoc_exists(:comments, is_spam: true)
    #
    #      # Using a String
    #      Post.where_assoc_exists(:comments, "is_spam = true")
    #
    #      # Using an Array (a string and its binds)
    #      Post.where_assoc_exists(:comments, ["is_spam = ?", true])
    #
    #   If the condition argument is blank, it is ignored (just like +#where+ does).
    #
    # [options]
    #   Some options are available to tweak how things queries are generated.
    #
    #   Their default values can be changed globally:
    #     # Somewhere in your setup code, such as an initializer in Rails
    #     ActiveRecordWhereAssoc.default_options[:ignore_limit] = true
    #
    #   Note, if you don't need a condition, you must pass nil as condition to provide options:
    #     Post.where_assoc_exists(:comments, nil, ignore_limit: true)
    #
    #   [ignore_limit]
    #     When true, +#limit+ and +#offset+ that are set from default_scope, on associations, and from
    #     +#has_one+ are ignored. <br>
    #     Removing the limit from +#has_one+ makes them be treated like a +#has_many+.
    #
    #     Main reasons to use ignore_limit: true
    #     * Needed for MySQL to be able to do anything with +#has_one+ associations because MySQL
    #       doesn't support sub-limit. <br>
    #       See {MySQL doesn't support limit}[https://github.com/MaxLap/activerecord_where_assoc#mysql-doesnt-support-sub-limit] <br>
    #       Note, this does mean the +#has_one+ will be treated as if it was a +#has_many+ for MySQL too.
    #     * You have a +#has_one+ association which you know can never have more than one record and are
    #       dealing with a heavy/slow query. The query used to deal with +#has_many+ is less complex, and
    #       may prove faster.
    #     * For this one special case, you want to check the other records that match your has_one
    #
    #   [never_alias_limit]
    #     When true, +#where_assoc_*+ will not use +#from+ to build relations that have +#limit+ or +#offset+ set
    #     on default_scope or on associations or for +#has_one+. <br>
    #     This allows changing the from as part of the conditions (such as for a scope)
    #
    #     Main reasons to use this: you have to use +#from+ in the block of +#where_assoc_*+ method
    #     (ex: because a scope needs +#from+).
    #
    #     Why this isn't the default:
    #     * From very few tests, the aliasing way seems to produce better plans.
    #     * Using aliasing produces a shorter query.
    #
    #   [poly_belongs_to]
    #     Specify what to do when a polymorphic belongs_to is encountered. Things are tricky because the query can
    #     end up searching in multiple Models, and just knowing which ones to look into can require an expensive query.
    #     It's also possible that you only want to search for those that match some specific Models, ignoring the other ones.
    #     [:pluck]
    #       Do a +#pluck+ in the column to detect to possible choices. This option can have a performance cost for big tables
    #       or when the query if done often, as the +#pluck+ will be executed each time
    #     [model or array of models]
    #       Specify which models to search for. This avoids the performance cost of +#pluck+ and can allow to filter some
    #       of the choices out that don't interest you. <br>
    #       Note, these are not instances, it's actual models, ex: <code>[Post, Comment]</code>
    #     [a hash]
    #       The keys must be models (same behavior as an array of models). <br>
    #       The values are conditions to apply only for key's model.
    #       The conditions are either a proc (behaves like the block, but only for that model) or the same things +#where+
    #       can receive. (String, Hash, Array, nil). Ex:
    #         List.where_assoc_exists(:items, nil, poly_belongs_to: {Car => "color = 'blue'",
    #                                                                Computer => proc { brand_new.where(core: 4) } })
    #     [:raise]
    #       (default) raise an exception when a polymorphic belongs_to is encountered.
    #
    # [&block]
    #   The block is used to add more complex conditions. The result behaves the same way
    #   as the 2nd argument's conditions, but lets you use any scoping methods, such as
    #   +#where+, +#joins+, nested +#where_assoc_*+ and scopes of the model. Note that using
    #   +#joins+ might lead to unexpected results when using #where_assoc_count, since if
    #   the joins adds rows, it will change the resulting count.
    #
    #   There are 2 ways of using the block for adding conditions to the association.
    #
    #   [A block that receives one argument]
    #     The block receives a relation on the target association and return a relation with added
    #     filters or may return nil to do nothing.
    #
    #        # Using a where for the added condition
    #        Post.where_assoc_exists(:comments) { |comments| comments.where(is_spam: true) }
    #
    #        # Applying a scope of the relation
    #        Post.where_assoc_exists(:comments) { |comments| comments.spam_flagged }
    #
    #        # Applying a scope of the relation, using the &:shortcut for procs
    #        Post.where_assoc_exists(:comments, &:spam_flagged)
    #
    #
    #   [A block that receives no argument]
    #     Instead of receiving the relation as argument, the relation is used as the "self" of
    #     the block. Everything else is identical to the block with one argument.
    #
    #        # Using a where for the added condition
    #        Post.where_assoc_exists(:comments) { where(is_spam: true) }
    #
    #        # Applying a scope of the relation
    #        Post.where_assoc_exists(:comments) { spam_flagged }
    #
    #     The main reason to use a block with an argument instead of without is when you need
    #     to call methods on the self outside of the block, such as:
    #
    #        Post.where_assoc_exists(:comments) { |comments| comments.where(id: self.something) }
    #
    def where_assoc_exists(association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_exists(self, association_name, conditions, options, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model doesn't exist.
    # Conditions the associated model must match to count as existing can also be specified.
    #
    # The parameters and everything is identical to #where_assoc_exists. The only
    # difference is that a record is matched if no matching association record that
    # fulfill the conditions are found.
    def where_assoc_not_exists(association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_not_exists(self, association_name, conditions, options, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on how many records for the specified association of the model exists. Conditions
    # the associated model must match can also be specified.
    #
    # This method is a generalization of #where_assoc_exists and #where_assoc_not_exists. Read
    # #where_assoc_exists first as this doc only describe the increased flexibility/power of #where_assoc_count.
    #
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
    # [left_operand]
    #   1st argument, the left side of the comparison. <br>
    #   One of:
    #   * a number
    #   * a string of SQL to embed in the query
    #   * a range (operator must be :== or :!=), will use BETWEEN or NOT BETWEEN<br>
    #     supports infinite ranges and exclusive end
    #
    # [operator]
    #   The operator to use, one of these symbols: <code>  :<  :<=  :==  :!=  :>=  :>  </code>
    #
    # [association_name, condition, options]
    #   Same as #where_assoc_exists' +association_name+, +condition+, +options+ arguments
    #
    # [&block]
    #   Same as #where_assoc_exists' block
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
    def where_assoc_count(left_operand, operator, association_name, conditions = nil, options = {}, &block)
      ActiveRecordWhereAssoc::CoreLogic.do_where_assoc_count(self, left_operand, operator, association_name, conditions, options, &block)
    end
  end
end
