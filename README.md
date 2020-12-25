# ActiveRecord Where Assoc

![Test supported versions](https://github.com/MaxLap/activerecord_where_assoc/workflows/Test%20supported%20versions/badge.svg)
[![Code Climate](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/gpa.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)

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

Here is an [introduction to this gem](INTRODUCTION.md).

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

Rails 4.1 to 6.1 are supported with Ruby 2.1 to 3.0.
Tested against SQLite3, PostgreSQL and MySQL. 
The gem only depends on the `activerecord` gem.

Add this line to your application's Gemfile:

```ruby
gem 'activerecord_where_assoc', '~> 1.0'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord_where_assoc

## Development state

This gem is feature complete and production ready.  
Other than rare tweaks as new versions of Rails and Ruby are released, there shouldn't be much activity on this repository.

## Documentation

The [documentation is nicely structured](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods.html)

If you prefer to see it in the code, the main methods are in [this file](https://github.com/MaxLap/activerecord_where_assoc/blob/master/lib/active_record_where_assoc/relation_returning_methods.rb)
and the ones that return SQL parts are in [this one](https://github.com/MaxLap/activerecord_where_assoc/blob/master/lib/active_record_where_assoc/sql_returning_methods.rb)

Here are some [usage tips](#usage-tips)

## Usage

You can view [many examples](EXAMPLES.md).

Otherwise, here is a short explanation of the main methods provided by this gem:

```ruby
where_assoc_exists(association_name, conditions, options, &block)
where_assoc_not_exists(association_name, conditions, options, &block)
where_assoc_count(left_operand, operator, association_name, conditions, options, &block)
```

* These methods add a condition (a `#where`) that checks if the association exists (or not)  
* You can specify condition on the association, so you could check only for comments that are made by an admin.  
* Each method returns a new relation, meaning you can chain `#where`, `#order`, `limit`, etc.  
* common arguments:
  * association_name: the association we are doing the condition on.
  * conditions: (optional) the condition to apply on the association. It can be anything that `#where` can receive, so: Hash, String and Array (string with binds).
  * options: [available options](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods#module-ActiveRecordWhereAssoc::RelationReturningMethods-label-Options) to alter some behaviors. (rarely necessary)
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
  The order of the parameters of `#where_assoc_count` may seem confusing, but you will get used to it. It helps to remember: the goal is to do: `5 < (SELECT COUNT(*) FROM ...)`, the number is first, then operator, then the association and its conditions.
  * left_operand:  
      * a number  
      * a string of SQL to embed in the query  
      * a range (operator must be `:==` or `:!=`)  
        will use SQL's `BETWEEN` or `NOT BETWEEN`  
        supports infinite ranges and exclusive end
  * operator: one of `:<`, `:<=`, `:==`, `:!=`, `:>=`, `:>`

## Intuition

Here is the basic intuition for the methods:

`#where_assoc_exists` filters the models, returning those *where* a record for the *association* matching a condition (by default any record in the association) *exists*.

`#where_assoc_not_exists` is the exact opposite of `#where_assoc_exists`. Filters the models, returning those *where* a record for the *association* matching a condition (by default any record in the association) do *not exists*

`#where_assoc_count` the more specific version of `#where_assoc_exists`. Filters the models, returning those *where* a record for the *association* matching a condition (by default any record in the association) do *not exists*

The condition that you may need on the record can be quite complicated. For this reason, you can pass a block to these methods.  
The block will receive a relation on records of the association. Your job is then to call `where` and scopes to specify what you want to exist (or to not exist if using `#where_assoc_not_exists`). 

So if you have `User.where_assoc_exists(:comments) {|rel| rel.where("content ilike '%github.com%'") }`, `rel` is a relation is on `Comment`, and you are specifying what you want to exist. So now we are looking for users that made a comment containing 'github.com'.

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

### Getting SQL strings

Sometimes, you may need only the SQL of the condition instead of a whole relation, such as when writing your own complex SQL. There are methods available for this use case: `assoc_exists_sql`, `assoc_not_exists_sql`, `compare_assoc_count_sql`, `only_assoc_count_sql`.

You can read some more about them in [their documentation](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/SqlReturningMethods.html)

Here is a simple example of they use. Note that they should always be called on the class.

```ruby
    # Users with a post or a comment
    User.where("#{User.assoc_exists_sql(:posts)} OR #{User.assoc_exists_sql(:comments)}")
    my_users.where("#{User.assoc_exists_sql(:posts)} OR #{User.assoc_exists_sql(:comments)}")
    # Note that this could be achieved in Rails 5 using the #or method and #where_assoc_exists
```

### The opposite of multiple nested EXISTS...

... is a single `NOT EXISTS` with the nested ones still using `EXISTS`.

All the methods always chain nested associations using an `EXISTS` when they have to go through multiple hoops. Only the outer-most, or first, association will have a `NOT EXISTS` when using `#where_assoc_not_exists` or a `COUNT` when using `#where_assoc_count`. This is the logical way of doing it.

### Using `#from` in scope

If you want to use a scope / condition which uses `#from`, then you need to use the [:never_alias_limit](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods.html#module-ActiveRecordWhereAssoc::RelationReturningMethods-label-3Anever_alias_limit+option) option to avoid `#where_assoc_*` being overwritten by your scope and getting a weird exception / wrong result.

## Known issues/limitations

### MySQL doesn't support sub-limit
On MySQL databases, it is not possible to use `has_one` associations and associations with a scope that apply either a limit or an offset.

I do not know of a way to do a SQL query that can deal with all the specifics of `has_one` for MySQL. If you have one, then please suggest it in an issue/pull request.

In order to work around this, you must use the [ignore_limit](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods.html#module-ActiveRecordWhereAssoc::RelationReturningMethods-label-3Aignore_limit+option) option. The behavior is less correct, but better than being unable to use the gem. 

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MaxLap/activerecord_where_assoc.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgements

* [René van den Berg](https://github.com/ReneB) for some of the code of [activerecord-like](https://github.com/ReneB/activerecord-like) used for help with setting up the tests
