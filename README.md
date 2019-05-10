# ActiveRecord Where Assoc

[![Build Status](https://travis-ci.org/MaxLap/activerecord_where_assoc.svg?branch=master)](https://travis-ci.org/MaxLap/activerecord_where_assoc)
[![Coverage Status](https://coveralls.io/repos/github/MaxLap/activerecord_where_assoc/badge.svg)](https://coveralls.io/github/MaxLap/activerecord_where_assoc)
[![Code Climate](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/gpa.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)
[![Issue Count](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/issue_count.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)

This gem makes it easy to do conditions based on the associations of your records in ActiveRecord (Rails). (Using SQL's `EXISTS` operator)

```ruby
# Find my_post's comments that were not made by an admin
my_post.comments.where_assoc_not_exists(:author, is_admin: true).where(...)
 
# Find every posts that have comments by an admin
Post.where_assoc_exists([:comments, :author], &:admins).where(...)
 
# Find my_user's posts that have at least 5 non-spam comments (not_spam is a scope on comments)
my_user.posts.where_assoc_count(5, :>=, :comments) { |comments| comments.not_spam }.where(...)
```

These allow for powerful, chainable, clear and easy to reuse queries. (Great for scopes)

You avoid many [problems with the alternative options](ALTERNATIVES_PROBLEMS.md).

Here are [many examples](EXAMPLES.md), including the generated SQL queries.

## Advantages

These methods have many advantages over the alternative ways of achieving the similar results:
* Avoids the [problems with the alternative ways](ALTERNATIVES_PROBLEMS.md)
* Can be chained and nested with regular ActiveRecord methods (`where`, `merge`, `scope`, etc).
* Adds a single condition in the `WHERE` of the query instead of complex things like joins.
  So it's easy to have multiple conditions on the same association
* Handles `has_one` correctly: only testing the "first" record of the association that matches the default_scope and the scope on the association itself.
* Handles recursive associations (such as parent/children) seemlessly.
* Can be used to quickly generate a SQL query that you can edit/use manually.

## Installation

Rails 4.1 to 6.0 are supported with Ruby 2.1 to 2.6.  
Works with SQLite3, PostgreSQL and MySQL. Untested with other RDBMS.

Add this line to your application's Gemfile:

```ruby
gem 'activerecord_where_assoc', '~> 1.0'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord_where_assoc

## Usage

The [documentation is nicely structured](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/QueryMethods.html)  
You can view [many examples](EXAMPLES.md).

Otherwise, here is a short explanation:

```ruby
where_assoc_exists(association_name, conditions, options, &block)
where_assoc_not_exists(association_name, conditions, options, &block)
where_assoc_count(left_operand, operator, association_name, conditions, options, &block)
```

* These methods add a condition (a `#where`) to the relation that checks if the association exists (or not)  
* You can specify condition on the association, so you could check only comments that are made by an admin.  
* Each method returns a new relation, meaning you can chain `#where`, `#order`, `limit`, etc.  
* common arguments:
  * association_name: the association we are doing the condition on.
  * conditions: (optional) the condition to apply on the association. It can be anything that `#where` can receive, so: Hash, String and Array (string with binds).
  * options: [available options](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/QueryMethods#module-ActiveRecordWhereAssoc::QueryMethods-label-Options) to alter some behaviors. (rarely necessary)
  * block: adds more complex conditions by receiving a relation on the association. Can use `#where`, `#where_assoc_*`, scopes, and other scoping methods.  
    Must return a relation.
    The block either:
    * receives no argument, in which case `self` is set to the relation, so you can do `{ where(id: 123) }`
    * receives arguments, in which case the block is called with the relation as first parameter.

    The block should return the new relation to use or `nil` to do as if there were no blocks.  
    It's common to use `where_assoc_*(..., &:scope_name)` to use a single scope.
* `#where_assoc_count` is a generalization of `#where_assoc_exists` and `#where_assoc_not_exists`. It behaves the same way, but is more powerful, as it allows you to specify how many matches there should be.
    ```ruby
    # These are equivalent:
    Post.where_assoc_exists(:comments, is_spam: true)
    Post.where_assoc_count(1, :<=, :comments, is_spam: true)

    Post.where_assoc_not_exists(:comments, is_spam: true)
    Post.where_assoc_count(0, :==, :comments, is_spam: true)

    # This has no equivalent (Posts with at least 5 spam comments)
    Post.where_assoc_count(5, :<=, :comments, is_spam: true)
    ```
* `where_assoc_count`'s additional arguments  
  The order of the parameters of `#where_assoc_count` can be confusingof may seem confusing, but you will get used to it. To help remember: the goal is to do: `5 < (SELECT COUNT(*) FROM ...)`, the number is first, then operator, then the association and its conditions.
  * left_operand:  
      * a number  
      * a string of SQL to embed in the query  
      * a range (operator must be `:==` or `:!=`)  
        will use SQL's `BETWEEN` or `NOT BETWEEN`  
        supports infinite ranges and exclusive end
  * operator: one of `:<`, `:<=`, `:==`, `:!=`, `:>=`, `:>`

## Usage tips

### Nested associations

Sometimes, there isn't a single association that goes deep enough. In that situation, you can simply nest the scopes:

```ruby
# Find users that have a post that has a comment that was made by an admin.
# Using &:admins to use the admins scope (or any other class method of comments)
User.where_assoc_exists(:posts) { |posts|
    posts.where_assoc_exists(:comments) { |comments| 
        comments.where_assoc_exists(:author, &:admins)
    }
}
```

If you don't need special conditions on any of the intermediary associations, then you can an array as shortcut for multiple steps:

```ruby
# Same as above
User.where_assoc_exists([:posts, :comments, :author], &:admins)
```

This shortcut can be used for every `where_assoc_*` methods. The conditions and the block will only be applied to the last association of the chain.


### Beware of spreading conditions on multiple calls

The following have different meanings:

```ruby
my_user.posts.where_assoc_exists(:comments_authors, is_admin: true, is_honest: true)

my_user.posts.where_assoc_exists(:comments_authors, is_admin: true)
             .where_assoc_exists(:comments_authors, is_honest: true)
```

The first is the posts of `my_user` that have a comment made by an honest admin. It requires a single comment to match every conditions.

The second is the posts of `my_user` that have a comment made by an admin and a comment made by someone honest. It could be the same comment (like the first query) but it could also be 2 different comments.

### Inter-table conditions

It's possible, with string conditions, to refer to all the tables that are used before the association, including the source model.

```ruby
# Find posts where the author also commented on the post.
Post.where_assoc_exists(:comments, "posts.author_id = comments.author_id")
```

Note that some database systems limit how far up you can refer to tables in nested queries. Meaning it's possible that the following query may get refused because of those limits:

```ruby
# it's hard to come up with a good example...
Post.where_assoc_exists([:comments, :author, :address], "addresses.country = posts.database_country")
```

Doing the same thing but with less associations between `address` and `posts` would not be an issue.

### The opposite of multiple nested EXISTS...

... is a single `NOT EXISTS` with the nested ones still using `EXISTS`.

All the methods always chain nested associations using an `EXISTS` when they have to go through multiple hoops. Only the outer-most, or first, association will have a `NOT EXISTS` when using `#where_assoc_not_exists` or a `COUNT` when using `#where_assoc_count`. This is the logical way of doing it.

### Using `#from` in scope

If you want to use a scope / condition which uses `#from`, then you need to use the [:never_alias_limit](#never_alias_limit) option to avoid `#where_assoc_*` being overwritten by your scope and getting a weird exception / wrong result.

## Known issues/limitations

### MySQL doesn't support sub-limit
On MySQL databases, it is not possible to use `has_one` associations and associations with a scope that apply either a limit or an offset.

I do not know of a way to do a SQL query that can deal with all the specifics of `has_one` for MySQL. If you have one, then please suggest it in an issue/pull request.

In order to work around this, you must use the [ignore_limit](#ignore_limit) option. The behavior is less correct, but better than being unable to use the gem. 

### has_* :through vs limit/offset
For `has_many` and `has_one` with the `:through` option, `#limit` and `#offset` are ignored. Note that `#limit` and `#offset` of the `:source` and of the `:through` side are applied correctly.

This is the opposite of what `ActiveRecord` does when you fetch the result of such an association. `ActiveRecord` will ignore the limits of the part `:source` and of the `:through` and only use the one of the `has_* :through`.

It is pretty complicated to support `#limit` and `#offset` of the `has_* :through` and would require quite a bit of refactoring. PR welcome

Note that the support of `#limit` and `#offset` for the `:source` and `:through` parts is a feature. I consider `ActiveRecord` wrong for not handling them correctly.

## Development

After checking out the repo, run `bundle install` to install dependencies.

Run `rake test` to run the tests for the latest version of rails. If you want SQL queries printed when you have failures, use `SQL_WITH_FAILURES=1 rake test`.

Run `bin/console` for an interactive prompt that will allow you to experiment in the same environment as the tests.

Run `bin/fixcop` to fix a lot of common styling mistake from your changes and then display the remaining rubocop rules you break. Make sure to do this before committing and submitting PRs. Use common sense, sometimes it's okay to break a rule, add a [rubocop:disable comment](http://rubocop.readthedocs.io/en/latest/configuration/#disabling-cops-within-source-code) in that situation.

Run `bin/testall` to test all supported rails/ruby versions:
* It will tell you about missing ruby versions, which you can install if you want to test for them
* It will run `rake test` on each supported version or ruby/rails
* It automatically installs bundler if a ruby version doesn't have it
* It automatically runs `bundle install`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MaxLap/activerecord_where_assoc.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgements

* [René van den Berg](https://github.com/ReneB) for some of the code of [activerecord-like](https://github.com/ReneB/activerecord-like) used for help with setting up the tests
