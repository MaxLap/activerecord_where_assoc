# frozen_string_literal: true

# See ActiveRecordWhereAssoc::QueryMethods
module ActiveRecordWhereAssoc
  # This module adds new variations of +#where+ to your Models/relations/associations/scopes.
  # These variations check if an association has records, so you can check if a +Post+ has
  # any +Comments+.
  #
  # These variations return a new relation (just like +#where+) so you can chain them with
  # other scoping methods such as +#where+, +#order+, +#limit+, more of these variations, etc.
  #
  # The arguments common to all methods are documented here at the top.
  #
  # For brevity, the examples are all directly on models, such as User, Post, Comment, but
  # the methods are available and behave the same on:
  # * associations: <tt>my_user.posts.where_assoc_exists(:comments)</tt>
  # * relations: <tt>Posts.where(serious: true).where_assoc_exists(:comments)</tt>
  # * scopes: (On the Post model) <tt>scope :with_comments, -> { where_assoc_exists(:comments) }</tt>
  # * models: <tt>Post.where_assoc_exists(:comments)</tt>
  #
  # You may also consider viewing the gem's README. It contains known issues and some tips.
  # You can view the {README on github}[https://github.com/MaxLap/activerecord_where_assoc/blob/master/README.md].
  #
  # If you need extra convincing to try this gem, I have a whole document with the problems of
  # the other ways of doing this kind of filtering:
  # {alternatives' problems}[https://github.com/MaxLap/activerecord_where_assoc/blob/master/ALTERNATIVES_PROBLEMS.md].
  #
  # === Association
  # The associations referred here are the links between your different models. They are your
  # +#belongs_to+, +#has_many+, +#has_one+, +#has_and_belongs_to_many+.
  #
  # This gem is about getting records from your database if their associations match (or don't
  # match) a certain condition (which by default is just to exist).
  #
  # Every method here has an *association_name* parameter. This is the association you want to
  # check if records exists.
  #
  #   # Posts with at least one comment
  #   Post.where_assoc_exists(:comments)
  #
  #   # Posts with no comments
  #   Post.where_assoc_not_exists(:comments)
  #
  # If you want, you can pass an array of associations. They will be followed in order, just
  # like a has_many :through would.
  #
  #   # Posts which have at least one comment with a reply
  #   # In other words: Posts which have at least one reply reachable through his comments
  #   Post.where_assoc_exists([:comments, :replies])
  #
  # === Condition
  # After the +association_name+ argument, you can pass additional conditions the associated
  # record must also match to be considered as existing.
  #
  # This +condition+ argument is passed directly to +#where+, so you can pass in the following:
  #
  #   # Posts that have at least one comment considered as spam
  #   # Using a Hash
  #   Post.where_assoc_exists(:comments, is_spam: true)
  #
  #   # Using a String
  #   Post.where_assoc_exists(:comments, "is_spam = true")
  #
  #   # Using an Array (a string and its binds)
  #   Post.where_assoc_exists(:comments, ["is_spam = ?", true])
  #
  #   If the condition is blank, it is ignored (just like +#where+ does).
  #
  # Note, if you specify multiple associations using an Array, the conditions will only be applied
  # to the last association.
  #
  #   # Users which have a post that has a comment marked as spam.
  #   # is_spam is only checked on the comment.
  #   User.where_assoc_exists([:posts, :comments], is_spam: true)
  #
  # If you want something else, you will need to use a block (see below) to nest multiple calls.
  #
  #   # Users which have a post made in the last 5 days which has comments
  #   User.where_assoc_exists(:posts) {
  #     where("created_at > ?", 5.days.ago).where_assoc_exists(:comments)
  #   }
  #
  # === Block
  # The block is used to add more complex conditions. The effect is the same as the condition
  # parameter, in that these conditions must be matched for the association to be considered
  # to exist, but lets you use any scoping methods, such as +#where+, +#joins+, nested
  # +#where_assoc_*+, scopes on the model, etc.
  #
  # Note that using +#joins+ might lead to unexpected results when using #where_assoc_count,
  # since if the joins adds rows, it will change the resulting count. It probably makes more
  # sense to, again, use one of the +where_assoc_*+ methods.
  #
  # There are 2 ways of using the block for adding conditions to the association.
  #
  # [A block that receives one argument]
  #   The block receives a relation on the target association and return a relation with added
  #   filters or may return nil to do nothing.
  #
  #     # These are all equivalent. Posts which have a comment marked as spam
  #     # Using a where for the added condition
  #     Post.where_assoc_exists(:comments) { |comments_scope| comments_scope.where(is_spam: true) }
  #
  #     # Applying a scope of the relation
  #     Post.where_assoc_exists(:comments) { |comments_scope| comments_scope.spam_flagged }
  #
  #     # Applying a scope of the relation, using the &:shortcut for procs
  #     Post.where_assoc_exists(:comments, &:spam_flagged)
  #
  # [A block that receives no argument]
  #   Instead of receiving the relation as argument, the relation is used as the "self" of
  #   the block. Everything else is identical to the block with one argument.
  #
  #     # These are all equivalent. Posts which have a comment marked as spam
  #     # Using a where for the added condition
  #     Post.where_assoc_exists(:comments) { where(is_spam: true) }
  #
  #     # Applying a scope of the relation
  #     Post.where_assoc_exists(:comments) { spam_flagged }
  #
  # The main reason to use a block with an argument instead of without one is when you need
  # to call methods on the self outside of the block, such as:
  #
  #   Post.where_assoc_exists(:comments) { |comments| comments.where(author_id: foo(:bar)) }
  #   Post.where_assoc_exists(:comments) { |comments| comments.where(author_id: self.foo(:bar)) }
  #   # In both cases, using the version without arguments would not work, since the #foo
  #   # would be called on the scope that was given to the block, instead of on the caller
  #   # of the #where_assoc_exists method.
  #
  #   # THESE ARE WRONG!
  #   Post.where_assoc_exists(:comments) { where(author_id: foo(:bar)) }
  #   Post.where_assoc_exists(:comments) { where(author_id: self.foo(:bar)) }
  #   # THESE ARE WRONG!
  #
  # If both +condition+ and +block+ are given, the conditions are applied first, and then the block.
  #
  # === Options
  # Some options are available to tweak how queries are generated. The default values of the options
  # can be changed globally:
  #
  #   # Somewhere in your setup code, such as an initializer in Rails
  #   ActiveRecordWhereAssoc.default_options[:ignore_limit] = true
  #
  # Or you can pass them as arguments after the +condition+ argument.
  #
  #   Post.where_assoc_exists(:comments, "is_spam = TRUE", ignore_limit: true)
  #   # Because this is 2 consecutive hashes, must use the +{}+
  #   Post.where_assoc_exists(:comments, {is_spam: true}, ignore_limit: true)
  #
  # Note, if you don't need a condition, you must pass nil as condition to provide options:
  #   Post.where_assoc_exists(:comments, nil, ignore_limit: true)
  #
  # ===== :ignore_limit option
  # When true, +#limit+ and +#offset+ that are set from default_scope, on associations, and from
  # +#has_one+ are ignored. <br>
  # Removing the limit from +#has_one+ makes them be treated like a +#has_many+.
  #
  # Main reasons to use ignore_limit: true
  # * Needed for MySQL to be able to do anything with +#has_one+ associations because MySQL
  #   doesn't support sub-limit. <br>
  #   See {MySQL doesn't support limit}[https://github.com/MaxLap/activerecord_where_assoc#mysql-doesnt-support-sub-limit] <br>
  #   Note, this does mean the +#has_one+ will be treated as if it was a +#has_many+ for MySQL too.
  # * You have a +#has_one+ association which you know can never have more than one record and are
  #   dealing with a heavy/slow query. The query used to deal with +#has_many+ is less complex, and
  #   may prove faster.
  # * For this one special case, you want to check the other records that match your has_one
  #
  # ===== :never_alias_limit option
  # When true, +#where_assoc_*+ will not use +#from+ to build relations that have +#limit+ or +#offset+ set
  # on default_scope or on associations or for +#has_one+. <br>
  # This allows changing the from as part of the conditions (such as for a scope)
  #
  # Main reasons to use this: you have to use +#from+ in the block of +#where_assoc_*+ method
  # (ex: because a scope needs +#from+).
  #
  # Why this isn't the default:
  # * From very few tests, the aliasing way seems to produce better plans.
  # * Using aliasing produces a shorter query.
  #
  # ===== :poly_belongs_to option
  # Specify what to do when a polymorphic belongs_to is encountered. Things are tricky because the query can
  # end up searching in multiple Models, and just knowing which ones to look into can require an expensive query.
  # It's also possible that you only want to search for those that match some specific Models, ignoring the other ones.
  # [:pluck]
  #   Do a +#pluck+ in the column to detect to possible choices. This option can have a performance cost for big tables
  #   or when the query if done often, as the +#pluck+ will be executed each time
  # [model or array of models]
  #   Specify which models to search for. This avoids the performance cost of +#pluck+ and can allow to filter some
  #   of the choices out that don't interest you. <br>
  #   Note, these are not instances, it's actual models, ex: <code>[Post, Comment]</code>
  # [a hash]
  #   The keys must be models (same behavior as an array of models). <br>
  #   The values are conditions to apply only for key's model.
  #   The conditions are either a proc (behaves like the block, but only for that model) or the same things +#where+
  #   can receive. (String, Hash, Array, nil). Ex:
  #     List.where_assoc_exists(:items, nil, poly_belongs_to: {Car => "color = 'blue'",
  #                                                            Computer => proc { brand_new.where(core: 4) } })
  # [:raise]
  #   (default) raise an exception when a polymorphic belongs_to is encountered.
  module QueryMethods
    # :section: Basic methods

    # Returns a new relation with a condition added (a +#where+) that checks if an association
    # of the model exists. Extra conditions the associated model must match can also be specified.
    #
    # You could say this is a way of doing a +#select+ that uses associations of your model
    # on the SQL side, but faster and more concise.
    #
    # Examples (with an equivalent ruby +#select+)
    #
    #   # Posts that have comments
    #   Post.where_assoc_exists(:comments)
    #   Post.all.select { |post| post.comments.exists? }
    #
    #   # Posts that have comments marked as spam
    #   Post.where_assoc_exists(:comments, is_spam: true)
    #   Post.select { |post| post.comments.any? {|comment| comment.is_spam } }
    #
    #   # Posts that have comments that have replies
    #   Post.where_assoc_exists([:comments, :replies])
    #   Post.select { |post| post.comments.any? {|comment| comment.replies.exists? } }
    #
    # [association_name]
    #   The association that must exist <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Association
    #
    # [condition]
    #   Extra conditions the association must match <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Condition
    #
    # [options]
    #   Options to alter the generated query <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Options
    #
    # [&block]
    #   More complex conditions the associated record must match (can also use scopes of the association's model) <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Block
    #
    def where_assoc_exists(association_name, conditions = nil, options = {}, &block)
      sql = ActiveRecordWhereAssoc::CoreLogic.where_assoc_exists_sql(self, association_name, conditions, options, &block)
      where(sql)
    end

    # Returns a new relation with a condition added (a +#where+) that checks if an association
    # of the model does not exist. Extra conditions the associated model that exists must not match
    # can also be specified.
    #
    # This the exact opposite of what #where_assoc_exists does, so a #where_assoc_not_exists with
    # the same arguments will keep every records that were rejected by the #where_assoc_exists.
    #
    # You could say this is a way of doing a +#reject+ that uses associations of your model
    # on the SQL side, but faster and more concise.
    #
    # Examples (with an equivalent ruby +#reject+)
    #
    #   # Posts that have no comments
    #   Post.where_assoc_not_exists(:comments)
    #   Post.all.reject { |post| post.comments.exists? }
    #
    #   # Posts that don't have comments marked as spam (but might have unmarked comments)
    #   Post.where_assoc_not_exists(:comments, is_spam: true)
    #   Post.reject { |post| post.comments.any? {|comment| comment.is_spam } }
    #
    #   # Posts that don't have comments that have replies (but can have comments that have no replies)
    #   Post.where_assoc_exists([:comments, :replies])
    #   Post.reject { |post| post.comments.any? {|comment| comment.replies.exists? } }
    #
    # [association_name]
    #   The association that must exist <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Association
    #
    # [condition]
    #   Extra conditions the association must not match <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Condition
    #
    # [options]
    #   Options to alter the generated query <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Options
    #
    # [&block]
    #   More complex conditions the associated record must match (can also use scopes of the association's model) <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Block
    #
    def where_assoc_not_exists(association_name, conditions = nil, options = {}, &block)
      sql = ActiveRecordWhereAssoc::CoreLogic.where_assoc_not_exists_sql(self, association_name, conditions, options, &block)
      where(sql)
    end

    # :section: Complex method

    # Returns a new relation with a condition added (a +#where+) that checks how many records an association
    # of the model has. Extra conditions the associated model must match can also be specified.
    #
    # This method is a generalization of #where_assoc_exists and #where_assoc_not_exists. It does the same
    # thing, but can be more precise over how many records should exist (and match the extra conditions)
    # To clarify, here are equivalent examples:
    #
    #   Post.where_assoc_exists(:comments)
    #   Post.where_assoc_count(1, :<=, :comments)
    #
    #   Post.where_assoc_not_exists(:comments)
    #   Post.where_assoc_count(0, :==, :comments)
    #
    # But these have no equivalent:
    #
    #   # Posts with at least 5 comments
    #   Post.where_assoc_count(5, :<=, :comments)
    #
    #   # Posts with less than 5 comments
    #   Post.where_assoc_count(5, :>, :comments)
    #
    # You could say this is a way of doing a +#select+ that +#count+ the associations of your model
    # on the SQL side, but faster and more concise.
    #
    # Examples (with an equivalent ruby +#select+ and +#count+)
    #
    #   # Posts with at least 5 comments
    #   Post.where_assoc_count(5, :<=, :comments)
    #   Post.all.select { |post| post.comments.count >= 5 }
    #
    #   # Posts that have at least 5 comments marked as spam
    #   Post.where_assoc_count(5, :<=, :comments, is_spam: true)
    #   Post.all.select { |post| post.comments.where(is_spam: true).count >= 5 }
    #
    #   # Posts that have at least 10 replies spread over their comments
    #   Post.where_assoc_count(10, :<=, [:comments, :replies])
    #   Post.select { |post| post.comments.sum { |comment| comment.replies.count } >= 5 }
    #
    # [left_operand]
    #   1st argument, the left side of the comparison. <br>
    #   One of:
    #   * a number
    #   * a string of SQL to embed in the query
    #   * a range (operator must be :== or :!=), will use BETWEEN or NOT BETWEEN<br>
    #     supports infinite ranges and exclusive end
    #
    #     # Posts with 5 to 10 comments
    #     Post.where_assoc_count(5..10, :==, :comments)
    #
    #     # Posts with less than 5 or more than 10 comments
    #     Post.where_assoc_count(5..10, :!=, :comments)
    #
    # [operator]
    #   The operator to use, one of these symbols: <code>  :<  :<=  :==  :!=  :>=  :>  </code>
    #
    # [association_name]
    #   The association that must have a certain number of occurrences <br>
    #   Note that if you use an array of association names, the number of the last association
    #   is what is counted.
    #
    #     # Users which have received at least 5 comments total (can be spread on all of their posts)
    #     User.where_assoc_count(5, :<=, [:posts, :comments])
    #
    #   See ActiveRecordWhereAssoc::QueryMethods@Association
    #
    # [condition]
    #   Extra conditions the association must match to count <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Condition
    #
    # [options]
    #   Options to alter the generated query <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Options
    #
    # [&block]
    #   More complex conditions the associated record must match (can also use scopes of the association's model) <br>
    #   See ActiveRecordWhereAssoc::QueryMethods@Block
    #
    # The order of the parameters may seem confusing. But you will get used to it. It helps
    # to remember that the goal is to do:
    #    5 < (SELECT COUNT(*) FROM ...)
    # So the parameters are in the same order as in that query: number, operator, association.
    #
    # To be clear, when you use multiple associations in an array, the count you will be
    # comparing against is the total number of records of that last association.
    #
    #   # The users that have received at least 5 comments total on all of their posts
    #   # So this can be from one post that has 5 comments of from 5 posts with 1 comments
    #   User.where_assoc_count(5, :<=, [:posts, :comments])
    #
    #   # The users that have at least 5 posts with at least one comments
    #   User.where_assoc_count(5, :<=, :posts) { where_assoc_exists(:comments) }
    #
    def where_assoc_count(left_operand, operator, association_name, conditions = nil, options = {}, &block)
      sql = ActiveRecordWhereAssoc::CoreLogic.where_assoc_count_sql(self, left_operand, operator, association_name, conditions, options, &block)
      where(sql)
    end
  end
end
