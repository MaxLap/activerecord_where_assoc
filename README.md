# ActiveRecord Where Assoc

[![Build Status](https://travis-ci.org/MaxLap/activerecord_where_assoc.svg?branch=master)](https://travis-ci.org/MaxLap/activerecord_where_assoc)
[![Coverage Status](https://coveralls.io/repos/github/MaxLap/activerecord_where_assoc/badge.svg)](https://coveralls.io/github/MaxLap/activerecord_where_assoc)
[![Code Climate](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/gpa.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)
[![Issue Count](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/issue_count.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)

NOTE: this gem is in active development:
 
* Expect it to be complete somewhere in August 2017. 
* Until it is complete, the gem won't be published on rubygems.
* Some of the docs you see might be for features that haven't been coded/tested yet.

This gem provides powerful methods to give you the power of SQL's EXISTS:

```
# Find my_post's comments that were not made by an admin
my_post.comments.where_assoc_not_exists(:author, is_admin: true).where(...)
 
# Find my_user's posts that have comments by an admin
my_user.posts.where_assoc_exists(:comments_authors, &:admins).where(...)
 
# Find my_user's posts that have at least 5 non-spam comments
my_user.posts.where_assoc_count(5, :>=, :comments) { |s| s.where(spam: false) }.where(...)
```

These allow for powerful, chainable, clear and easy to reuse scopes. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord_where_assoc'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord_where_assoc

## Usage

### `#where_assoc_exists` & `#where_assoc_not_exists`
 
* The first parameter is the association we are doing the condition on.
* The second parameter (optional) is the condition to apply on the association. It can be anything that #where can receive, so: Hash, String, Array (string with binds), Arel node.
* A block can also be passed. It can add conditions on the association's relation after all the conditions have been applied (association's scopes, default_scope, second parameter of the method).
  The block either:
  * Receive no argument, in that case self is set to the relation, so you can do { where(id: 123) }
  * Receive arguments, in that case, the block is called with the relation as first parameter
  The block should return the new relation to use or `nil` to do as if there were no blocks
  It's common to use where_assoc_*(..., &:scope_name) to apply a single scope quickly
  
### `#where_assoc_count`

* The first parameter is a number.
* The second parameter is the operator to use: `:<`, `:<=`, `:==`, `:>=`, `:>`
* The third and fourth parameters and the block are the same as the first and second parameters of `#where_assoc_exists`.

The order of the parameters may seem confusing. If you have better alternatives to suggest, feel free to open an issue to discuss this.

To help remember the order of the parameters, remember that the goal is to do:

    5 < (SELECT COUNT(*) FROM ...)

The parameters are in the same order as in that query: number, operator, association

## Supported Rails versions

Rails 5.1, 5.0, 4.2 and 4.1 are supported for every Ruby versions they support. Just install the gem as usual.

## More examples

```ruby
# Find my_post's comments that were not made by an admin
# Uses a Hash for the condition
my_post.comments.where_assoc_not_exists(:author, is_admin: true)

# Find my_user's posts that have comments by an admin
# Uses the block shortcut to use a scope that exists on Author
my_user.posts.where_assoc_exists(:comments_authors, &:admins)

# Find my_user's posts that have at least 5 non-spam comments
# Uses a block with a parameter to do a condition
my_user.posts.where_assoc_count(5, :>=, :comments) { |s| s.where(spam: false) }

# Find my_user's posts that have at least 5 non-spam comments
# Uses a block without parameters to do a condition
my_user.posts.where_assoc_count(5, :>=, :comments) { where(spam: false) }

# Find my_user's posts that have comments by an honest admin
# Uses multiple associations.
# Uses a hash as 2nd parameter to do the conditions
my_user.posts.where_assoc_exists([:comments, :author], honest: true, is_admin: true)
```

## Usage tips

### Nested associations

Sometimes, there isn't a single association that goes deep enough. In that situation, you can simply nest the scopes:

```ruby
# Find users that have a post that has a comment that was made by an admin.
# Using &:is_admin to use the is_admin scope (or any other class method of comments)
User.where_assoc_exists(:posts) { |posts|
    posts.where_assoc_exists(:comments) { |comments| 
        comments.where_assoc_exists(:author, &:is_admin)
    }
}
```

If you don't need special conditions on any of the intermediary associations, then you can use a shortcut:

```ruby
# Same as above
User.where_assoc_exists([:posts, :comments, :author], &:is_admin)
```

This shortcut can be used for every methods. The conditions and the block will be applied only to the last assocation of the chain.


### Beware of spreading conditions on multiple calls

The following have different meanings:

```ruby
my_user.posts.where_assoc_exists(:comments_authors, is_admin: true, honest: true)

my_user.posts.where_assoc_exists(:comments_authors, is_admin: true)
             .where_assoc_exists(:comments_authors, honest: true)
```

The first is the posts of my_user that have a comment made by an honest admin.

The second is the posts of my_user that have a comment made by an admin and a comment made by someone honest. In this case, it would match a post with 2 comments, one by an admin and one by someone honest. The first example requires the same comment to be by an admin and by someone honest.

### Inter-table conditions

It's possible, with string conditions, to refer to all the tables that are used before the association, including the source model.

```ruby
# Find posts where the author also commented on the post.
Post.where_assoc_exists(:comments, "posts.author_id = comments.author_id")
```

### The opposite of multiple nested EXISTS...

... is a single NOT EXISTS with then nested ones still using EXISTS.

All the methods always chain nested associations using an EXISTS when they have to go through multiple hoops. Only the outer-most, or first, association will have a NOT EXISTS when using `#where_assoc_not_exists` or a COUNT when using `#where_assoc_count`.

## Advantages
These methods many advantages over the alternative ways of achieving the similar results:
* Can be chained and nested with regular ActiveRecord scoping methods.
* They return relations with with a single added condition in the `WHERE` of the query.
  * You can easily have multiple conditions on different records of an association
* There is no joins needed:
  * No need for `#distinct` to remove duplicated records that are added by the joins. 
    (Avoids subtle bugs caused by unexpected `#distinct` in a scope) 
  * There are no duplicated results returned as you could have with joins & conditions
* Does not affect `includes` and `eager_load`
  * ActiveRecord only eager loads the records that match conditions the conditions of the query, which can lead to unexpected bugs.
* Applies the scope that was defined on the associations
* Applies the default_scopes that was defined on the target model
* Handles has_one correctly: Only testing the "first" record of the association that matches the default_scope and the scope on the association itself.

## Known issues/limitations

MySQL is terrible: On MySQL databases, it is not possible to use has_one associations and associations with a scope that apply either a limit or an offset.
I do not know of a way to do a query that does all the specifics of has_one for MySQL. If you have one, then you may propose in an issue/pull request.

`has_many` and `has_one` using the `:through` option cannot have a scope that uses either `#limit` or `#offset`.
Making such cases work is pretty complicated and would require quite a bit of refactoring. So if a real need and use case is made, this may get fixed.  
`#limit` and `#offset` work fine in the scope of associations that do not use `:through`.

## Development

After checking out the repo, run `bundle install` to install dependencies.

Run `rake test` to run the tests for the latest version of rails

Run `bin/console` for an interactive prompt that will allow you to experiment in the same environment as the tests.

Run `bin/fixcop` to fix a lot of common styling mistake of your code, make sure to do this before commiting and submitting.

Run `rubocop` to see all the other rules that you break. Use common sense, sometimes it's okay to break a rule, add a [rubocop:disable comment](http://rubocop.readthedocs.io/en/latest/configuration/#disabling-cops-within-source-code) in that situation.

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
