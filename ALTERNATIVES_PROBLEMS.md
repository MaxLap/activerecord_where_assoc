There are multiple ways of achieving results similar to what this gems does using either only built-in ActiveRecord functionalities or other gems.

This is a list of some of those alternatives, explaining what issues they have or reasons to prefer this gem over them.


## Too long; didn't read

**Use this gem, you will avoid problems and save time**

* No more having to choose, case by case, which way has the less problems.  
  Just use `#where_assoc_*` each time and avoid every problems.
* Need less raw SQL, which means less code, more clarity and less maintenance.
* Allows powerful scopes without traps.
* Handles recursive associations correctly.
* Handles has_one correctly.
* Handles polymorphic belongs_to

## Short version

Summary of the problems of the alternatives that `activerecord_where_assoc` solves. The following sections go in more details.

* every alternatives (except raw SQL):
  * treat `has_one` like a `has_many`.
  * can't handle recursive associations. (ex: parent/children)
  * no simple way of checking for more complex counts. (such as `less than 5`)
* `joins` / `includes`:
  * doing `not exists` with conditions requires a `LEFT JOIN` with the conditions as part of the `ON`, which requires raw SQL.
  * checking for 2 sets of conditions on different records of the same association won't work. (so your scopes can be incompatible)
  * can't be used with Rails 5's `or` unless both sides do the same `joins` / `includes` / `eager_load`.
  * Doesn't work for polymorphic belongs_to.
* `joins`:
  * `has_many` may return duplicate records.
  * using `uniq` / `distinct` to solve duplicate rows is an unexpected side-effect when this is in a scope.
* `includes`:
  * triggers eagerloading, which makes your `scope` have unexpected bad performances if it's not necessary.
  * when using a condition, the eagerloaded records are also filtered, which is very bug-prone when in a scope.
* raw SQL:
  * verbose, less clear on the goal of the queries (you don't even name the association the query is about).
  * need to repeat conditions from the association / default_scope.
* `where_exists` gem:
  * can't use scopes of the association's model.
  * can't go deeper than one level of association.

## Common problems to most alternatives

These are problems that affect most alternatives. Details are written in this section and just referred to by a one liner when they apply to an alternative.

### Treating has_one like has_many

Every alternative treats a has_one just like a has_many. So if any of the records (instead of only the first) matches your condition, you will get a match.

And example to clarify:

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  has_one :current_address, -> { order("effective_date DESC") }, class_name: 'Address'
end

# This correctly matches only those whose current_address is in Montreal
Person.where_assoc_exists(:current_address, city: 'Montreal')

# Every alternatives (except raw SQL):
# Matches those that have had an address in Montreal, no matter when
Person.where_assoc_exists(:addresses, city: 'Montreal')
```

The general version of this problem is the handling of `limit` and `offset` on associations and in default_scopes. where_assoc_exists handle those correctly and only checks the records that match the limit and the offset.

### Raw SQL joins or sub-selects

Having to write the joins and conditions in raw SQL is more painful and more error prone than having a method do it for you. It hides the important details of what you are doing in a lot of verbosity.

If there are conditions set on either the association or a default_scope of the model, then you must rewrite those conditions in your manual joins and your manual sub-selects. Worst, if you add/change those conditions on the association / default_scope, then you must find every raw SQL that apply and do the same operation.

```ruby
class Post < ActiveRecord::Base
  # Any raw SQL doing a join or sub-select on public_comments, if it want to be representative,
  # must repeat "public = true".
  has_many :public_comments, -> { where(public: true) }, class_name: 'Comment'
end

class Comment < ActiveRecord::Base
  # Any raw SQL doing a join or sub-select to this model, if it want to be representative,
  # must repeat "deleted_at IS NULL".
  default_scope -> { where(deleted_at: nil) }
end
```

All of this is avoided by where_assoc_* methods.

### Unable to handle recursive associations

When you have recursive associations such as parent/children, you must compare multiple rows of the same table. To do this, you have no choice but to write your own raw SQL to, at the very least, do a SQL join with an alias.

This brings us back to the [raw SQL joins](#raw-sql-joins-or-sub-selects) problem.

`where_assoc_*` methods handle this seemlessly.

### Unable to handle polymorphic belongs_to

When you have a polymorphic belongs_to, you can't use `joins` or `includes` in order to do queries on it. You have to use manual SQL ([raw SQL joins](#raw-sql-joins-or-sub-selects)) or a gem that provides the feature, such as `activerecord_where_assoc`.

## ActiveRecord only

Those are the common ways given in stack overflow answers.

### Using `joins` and `where`

```ruby
Post.where_assoc_exists(:comments, is_spam: true)
Post.joins(:comments).where(comments: {is_spam: true})
```

* If the association maps to multiple records (such as with a has_many), then the the relation will return one record for each matching association record. In this example, you would get the same post twice if it has 2 comments that are marked as spam.  
  Using `uniq` can solve this issue, but if you do that in a scope, then that scope unexpectedly adds a DISTINCT to your query, which can lead to unexpected results if you actually wanted duplicates for a different reason.

* Doing the opposite is a lot more complicated, as seen below. You have to include your conditions directly in the join and use a LEFT JOIN, this means writing the whole thing in raw SQL, and then you must check for the id of the association to be empty.

```ruby
Post.where_assoc_not_exists(:comments, is_spam: true)
Post.joins("LEFT JOIN comments ON posts.id = comments.post_id AND comments.is_spam = true").where(comments: {id: nil})
```

Writing a raw join like that has yet more problems: [raw SQL joins](#raw-sql-joins-or-sub-selects)

* If you want to have another condition referring to the same association (or just the same table), then you need to write out the SQL for the second join using an alias. Therefore, your scopes are not even compatible unless each of them has a join with a unique alias.

```ruby
# We want to be able to match either different or the same records
Post.where_assoc_exists(:comments, is_spam: true)
    .where_assoc_exists(:comments, is_reported: true)

# Please don't ever do this, this just shows how painful it would be
# If you reach the need to do this but won't use where_assoc_exists,
# go for a regular #where("EXISTS( SELECT ...)")
Post.joins(:comments).where(comments: {is_spam: true})
    .joins("JOIN comments comments_for_reported ON posts.id = comments_for_reported.post_id")
    .where(comments_for_reported: {is_reported: true})
```

* Cannot be used with Rails 5's `or` unless both side do the same `joins`.
* [Treats has_one like a has_many](#treating-has_one-like-has_many)
* [Can't handle recursive associations](#unable-to-handle-recursive-associations)
* [Can't handle polymorphic belongs_to](#unable-to-handle-polymorphic-belongs_to)

### Using `includes` (or `eager_load`) and `where`

This solution is similar to the `joins` one above, but avoids the need for `uniq`. Every other problems of the `joins` remain. You also add other potential issues.

```ruby
Post.where_assoc_exists(:comments, is_spam: true)
Post.eager_load(:comments).where(comments: {is_spam: true})
```

* You are triggering the loading of potentially lots of records that you might not need. You don't expect a scope like `have_reported_comments` to trigger eager loading. This is a performance degradation.

* The eager loaded records of the association are actually also filtered by the conditions. All of the posts returned will only have the comments that are spam.  
  This means if you iterate on `Post.have_reported_comments` to display each of the comments of the posts that have at least one reported comment, you are actually only going to display the reported comments. This may be what you wanted to do, but it clearly isn't intuitive.

* Cannot be used with Rails 5's `or` unless both side do the same `includes` or `eager_load`.

* [Treats has_one like a has_many](#treating-has_one-like-has_many)
* [Can't handle recursive associations](#unable-to-handle-recursive-associations)
* [Can't handle polymorphic belongs_to](#unable-to-handle-polymorphic-belongs_to)

* Simply cannot be used for complex cases.

Note: using `includes` (or `eager_load`) already does a LEFT JOIN, so it is pretty easy to do a "not exists", but only if you don't need any condition on the association (which would normally need to be in the JOIN clause):

```ruby
Post.where_assoc_exists(:comments)
Post.eager_load(:comments).where(comments: {id: nil})
```

### Using `where("EXISTS( SELECT... )")`

This is what is gem does behind the scene, but doing it manually can lead to troubles:

* Problems with writing [raw SQL sub-selects](#raw-sql-joins-or-sub-selects)

* Unless you do a quite complex nested sub-selects, you will [treat has_one like a has_many](#treating-has_one-like-has_many)


## Gems

### where_exists

https://github.com/EugZol/where_exists

An interesting gem that also does `EXISTS (SELECT ... )` behind the scene. Solves most issues from ActiveRecord only alternatives, but appears less powerful than where_assoc_exists.

* where_exists supports polymorphic belongs_to only by always doing a `pluck` everytime. In some situation could be a slow query if there is a lots of rows to scan. where_assoc also allows directly specifying the classes manually, avoiding the pluck and possibly filtering the choices.
  
* Unable to use scopes of the association's model.
```ruby
# There is no equivalent for this (admins is a scope on User)
Comment.where_assoc_exists(:author, &:admins)
```

* Cannot use a block for more complex conditions
```ruby
# There is no equivalent for this
Comment.where_assoc_exists(:author) { admins.where("created_at <= ?", 1.month.ago) }
```

* Unable to dig deeper in the associations  
  Note: it does follow :through associations so doing a custom associations for your need can be a workaround.

```ruby
# There is no equivalent for this (Users that have posts with at least a comments)
User.where_assoc_exists([:posts, :comments])
```

* Has no equivalent to `where_assoc_count`
```ruby
# There is no equivalent for this (posts with more than 5 comments)
Post.where_assoc_count(:comments, :>, 5)
```

* [Treats has_one like a has_many](#treating-has_one-like-has_many)

* [Can't handle recursive associations](#unable-to-handle-recursive-associations)

* `where_exists` is shorter than `where_assoc_exists`, but it is also less obvious about what it does.  
  In any case, it is trivial to alias one name to the other one.

* where_exists supports Rails 4.2 and up, while where_assoc supports Rails 4.1 and up.
