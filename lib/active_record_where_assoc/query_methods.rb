# frozen_string_literal: true

require_relative "helpers"
require_relative "exceptions"

module ActiveRecordWhereAssoc
  module QueryMethods
    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model exists. Conditions
    # the associated model must match can also be specified.
    #
    # As first argument, you must specify the association to check against. This can be
    # any of the associations on the current relation's model.
    #
    #     # Posts that have at least one comment
    #     Post.where_assoc_exists(:comments)
    #
    # #where_assoc_exists accepts a block to add conditions that the association must match
    # to be accepted for the exist test.
    #
    # === block that receives an argument
    #
    # The block receives a relation on the target association and return a relation with added
    # filters or may return nil.
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
    # === block that receives no argument
    #
    # Instead of receiving the relation as argument, the relation is used as the "self" of
    # the block.
    #
    #    # Using a where for the added condition
    #    Post.where_assoc_exists(:comments) { where(spam_flag: true) }
    #
    #    # Applying a scope of the relation
    #    Post.where_assoc_exists(:comments) { spam_flagged }
    #
    # The main reason not to use this and use a block with an argument is when you need to
    # call methods on the real self of the block, such as:
    #
    #    Post.where_assoc_exists(:comments) { |comments| comments.where(id: self.something) }
    #
    # === the condition argument (second argument)
    #
    # #where_assoc_exists can receive an argument after the association's name as a shortcut
    # for using a single where call. The argument is passed to #where.
    #
    #    # Using a Hash
    #    Post.where_assoc_exists(:comments, spam_flag: true)
    #
    #    # Using a String
    #    Post.where_assoc_exists(:comments, "spam_flag = true")
    #
    #    # Using an Array (a string and its binds)
    #    Post.where_assoc_exists(:comments, ["spam_flag = ?", true])
    #
    # If the second argument is blank-ish, it is ignored (as #where does).
    def where_assoc_exists(association_name, given_scope = nil, &block)
      ActiveRecordWhereAssoc::Refacted.where_assoc_exists(self, association_name, given_scope, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on if a record for the specified association of the model doesn't exist.
    #
    # See #where_assoc_exists for usage details. The only difference is that a record
    # is matched if no matching association record is found.
    def where_assoc_not_exists(association_name, given_scope = nil, &block)
      ActiveRecordWhereAssoc::Refacted.where_assoc_not_exists(self, association_name, given_scope, &block)
    end

    # Returns a new relation, which is the result of filtering the current relation
    # based on how many records for the specified association of the model exists. Conditions
    # the associated model must match can also be specified.
    #
    # #where_assoc_count is a generalization of #where_assoc_exists, allowing you to
    # for example, filter for comments that have at least 2 matching posts
    def where_assoc_count(left_operand, operator, association_name, given_scope = nil, &block)
      ActiveRecordWhereAssoc::Refacted.where_assoc_count(self, left_operand, operator, association_name, given_scope, &block)
    end
  end
end
