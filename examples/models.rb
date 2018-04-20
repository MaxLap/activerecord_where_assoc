# frozen_string_literal: true

# These models are available in bin/console
#
# And easy way to play with these (it will create an sqlite3 DB in memory):
#
#     git clone git@github.com:MaxLap/activerecord_where_assoc.git
#     cd activerecord_where_assoc
#     bundle install
#     bin/console
#
class User < ActiveRecord::Base
  has_many :posts, foreign_key: "author_id"
  has_many :comments, foreign_key: "author_id"

  scope :admins, -> { where(is_admin: true) }
end

class Post < ActiveRecord::Base
  belongs_to :author, class_name: "User"
  has_many :comments
  has_many :comments_author, through: :comments

  # Easy and powerful scope examples
  scope :by_admin, -> { where_assoc_exists(:author, &:admins) }
  scope :commented_on_by_admin, -> { where_assoc_exists(:comments, &:by_admin) }
  scope :with_many_reported_comments, lambda {|min_nb=5| where_assoc_count(min_nb, :<=, :comments, &:reported) }
end

class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :author, class_name: "User"

  scope :reported, -> { where(is_reported: true) }
  scope :spam, -> { where(is_spam: true) }

  # Easy and powerful scope examples
  scope :by_admin, -> { where_assoc_exists(:author, &:admins) }
end
