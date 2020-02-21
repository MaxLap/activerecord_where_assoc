# frozen_string_literal: true

# To update the examples, run this from the project's root dir:
#   `ruby examples/examples.rb > EXAMPLES.md`

# Avoid a message about default database used
ENV["DB"] ||= "sqlite3"
require "active_support/core_ext/string/strip"
require_relative "../test/support/load_test_env"
require_relative "schema"
require_relative "models"
require_relative "some_data"
require "niceql"

class Examples
  def puts_doc
    puts <<-HEADER.strip_heredoc
      Here are some example usages of the gem, along with the generated SQL.

      Each of those methods can be chained with scoping methods, so they can be used on `Post`, `my_user.posts`, `Post.where('hello')` or inside a scope. Note that for the `*_sql` variants, those should preferably be used on classes only, because otherwise, it could be confusing for a reader.

      The models can be found in [examples/models.md](examples/models.md). The comments in that file explain how to get a console to try the queries. There are also example uses of the gem for scopes.

      The content of this file is generated from running `ruby examples/examples.rb > EXAMPLES.md`

      -------

    HEADER

    puts "## Simple examples"
    puts

    output_example(<<-DESC, <<-RUBY)
      Posts that have a least one comment
    DESC
      Post.where_assoc_exists(:comments)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Posts that have no comments
    DESC
      Post.where_assoc_not_exists(:comments)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Posts that have a least 50 comment
    DESC
      Post.where_assoc_count(50, :<=, :comments)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Users that have made posts
    DESC
      User.where_assoc_exists(:posts)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Users that have made posts that have comments
    DESC
      User.where_assoc_exists([:posts, :comments])
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Users with a post or a comment (without using ActiveRecord's `or` method)
      Using `my_users` to highlight that *_sql methods should always be called on the class
    DESC
      my_users.where("\#{User.assoc_exists_sql(:posts)} OR \#{User.assoc_exists_sql(:comments)}")
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Users with a post or a comment (using ActiveRecord's `or` method)
    DESC
      User.where_assoc_exists(:posts).or(User.where_assoc_exists(:comments))
    RUBY

    puts "## Examples with condition / scope"
    puts

    output_example(<<-DESC, <<-RUBY)
      comments of `my_post` that were made by an admin (Using a hash)
    DESC
      my_post.comments.where_assoc_exists(:author, is_admin: true)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      comments of `my_post` that were not made by an admin (Using scope)
    DESC
      my_post.comments.where_assoc_not_exists(:author, &:admins)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Posts that have at least 5 reported comments (Using array condition)
    DESC
      Post.where_assoc_count(5, :<=, :comments, ["is_reported = ?", true])
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Posts made by an admin (Using a string)
    DESC
      Post.where_assoc_exists(:author, "is_admin = 't'")
    RUBY

    output_example(<<-DESC, <<-RUBY)
      comments of `my_post` that were not made by an admin (Using block and a scope)
    DESC
      my_post.comments.where_assoc_not_exists(:author) { admins }
    RUBY

    output_example(<<-DESC, <<-RUBY)
      Posts that have 5 to 10 reported comments (Using block with #where and range for count)
    DESC
      Post.where_assoc_count(5..10, :==, :comments) { where(is_reported: true) }
    RUBY

    output_example(<<-DESC, <<-RUBY)
      comments made in replies to my_user's post
    DESC
      Comment.where_assoc_exists(:post, author_id: my_user.id)
    RUBY

    puts "## Complex / powerful examples"
    puts

    output_example(<<-DESC, <<-RUBY)
      posts with a comment by an admin (uses array to go through multiple associations)
    DESC
      Post.where_assoc_exists([:comments, :author], is_admin: true)
    RUBY

    output_example(<<-DESC, <<-RUBY)
      posts where the author also commented on the post (uses a conditions between tables)
    DESC
      Post.where_assoc_exists(:comments, "posts.author_id = comments.author_id")
    RUBY

    output_example(<<-DESC, <<-RUBY)
      posts with a reported comment made by an admin (must be the same comments)
    DESC
      Post.where_assoc_exists(:comments, is_reported: true) {
        where_assoc_exists(:author, is_admin: true)
      }
    RUBY

    output_example(<<-DESC, <<-RUBY, footer: false)
      posts with a reported comment and a comment by an admin (can be different or same comments)
    DESC
      my_user.posts.where_assoc_exists(:comments, is_reported: true)
                   .where_assoc_exists([:comments, :author], is_admin: true)
    RUBY

    output_example(<<-DESC, <<-RUBY, footer: false)
      Users with more posts than comments
      Using `my_users` to highlight that *_sql methods should always be called on the class
    DESC
      my_users.where("\#{User.only_assoc_count_sql(:posts)} > \#{User.only_assoc_count_sql(:comments)}")
    RUBY
  end


  # Below is just helpers for #puts_doc

  def my_post
    Post.order(:id).first
  end

  def my_user
    User.order(:id).first
  end

  def my_users
    User.all
  end

  def my_comment
    User.order(:id).first
  end

  def output_example(description, ruby, footer: true)
    description = description.strip_heredoc
    ruby = ruby.strip_heredoc

    relation = eval(ruby) # rubocop:disable Security/Eval
    # Just making sure the query doesn't fail
    relation.to_a

    # #to_niceql formats the SQL a little
    sql = relation.to_niceql

    puts "```ruby"
    puts description.split("\n").map { |s| "# #{s}" }.join("\n")
    puts ruby
    puts "```"
    puts "```sql\n#{sql}\n```"

    return unless footer

    puts
    puts "---"
    puts
  end
end

# Lets make this a little denser
Niceql::Prettifier::INLINE_VERBS << "|FROM"

Examples.new.puts_doc
