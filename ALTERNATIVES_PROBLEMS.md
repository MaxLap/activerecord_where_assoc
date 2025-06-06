There are multiple ways of achieving results similar to what this gems does using either only built-in
ActiveRecord functionalities or other gems.

This is a list of some of those alternatives, explaining what issues they have or reasons to prefer this gem over them.


## Too long; didn't read

**Use this gem, you will avoid problems and save time**

* No more having to choose, case by case, which way has the less problems.
  Just use `#where_assoc_*` each time and avoid every problems.
* Need less raw SQL, which means less code, more clarity and less maintenance.
* Generates a single `#where`. No weird side-effects things like `#eager_load` or `#join`
  This makes well-behaved scopes, you can even have multiple conditions on the same association
* Handles recursive associations correctly.
* Handles has_one correctly (Except [MySQL has a limitation](README.md#mysql-doesnt-support-sub-limit)).
* Handles polymorphic belongs_to

## Short version

Summary of the problems of the alternatives that the `activerecord_where_assoc` gem solves. The following sections go in more details.

* every alternatives (except raw SQL):
  * treat `#has_one` like a `#has_many`.
  * can't handle recursive associations nicely. (ex: parent/children)
  * no simple way of checking for more complex counts. (such as `less than 5`)
* `#joins` / `#includes`:
  * doing `not exists` with conditions requires a `LEFT JOIN` with the conditions as part of the `ON`, which requires raw SQL.
  * checking for 2 sets of conditions on different records of the same association won't work without extra things.
    (so your scopes can be incompatible)
  * can't be used with Rails 5's `#or`.
  * doesn't work for polymorphic belongs_to.
  * doesn't compose well.
* `joins`:
  * `has_many` may return duplicate records.
  * using `uniq` / `distinct` to solve duplicate rows is an unexpected side-effect when this is in a scope.
* `#includes`:
  * triggers eagerloading, which makes your `scope` have unexpected bad performances if it's not necessary.
  * when using a condition, the eagerloaded records are also filtered, which is very bug-prone when in a scope.
* raw SQL:
  * verbose, less clear on the goal of the queries (you don't even name the association the query is about).
  * need to repeat conditions from the association / default_scope.
* `#where_exists` gem:
  * No other problems than the ones common to every alternatives written above.

## Common problems to most alternatives

These are problems that affect most alternatives. Details are written in this section and just referred to
by a one liner when they apply to an alternative.

### Treating has_one like has_many

Every alternative treats a has_one just like a has_many. So if any of the records (instead of only the first)
matches your condition, you will get a match.

And example to clarify:

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  has_one :current_address, -> { order("effective_date DESC") }, class_name: 'Address'
end

# This correctly matches only those whose current_address is in Montreal
Person.where_assoc_exists(:current_address, city: 'Montreal')

# In every alternatives (except raw SQL), doing a joins or anything else on :current_address will
# actually do the exact same thing as doing it on :addresses. So their effect will be identical to:
Person.where_assoc_exists(:addresses, city: 'Montreal')
```

The general version of this problem is to handle `#limit` and `#offset` on associations and in default_scopes.

`#where_assoc_*` methods handle `#limit`, `#offset` and `#has_one` correctly and checks that the records that
match the limit and the offset also match the condition.

Note: [MySQL has a limitation](README.md#mysql-doesnt-support-sub-limit), this makes handling has_one correctly
not possible with MySQL.

### Raw SQL joins or sub-selects

Having to write the joins and conditions in raw SQL is more painful and more error prone than having a method
do it for you. It hides the important details of what you are doing in a lot of verbosity.

If there are conditions set on either the association or a default_scope of the model, then you must rewrite
those conditions in your manual joins and your manual sub-selects. Worst, if you add/change those conditions
on the association / default_scope, then you must find every raw SQL that apply and do the same operation.

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

All of this is done for you by the `#where_assoc_*` methods.

### Incompatible with `#or`

Using `#joins`, `#includes` + `#references`, `#eager_load` affects the query as a whole. This means you can't
use tools that only interact with the conditions.

For example, you can't use `#or`, because that just deals with the conditions (the `#where`), but if one of
your relation has a `#joins`, the implicit "condition" that "there must be a record" is not part of the `#where`.

Actually, the `#or` will refuse to mix queries that mismatch structurally:

```ruby
# Posts by an admin or that have comments.
# This will raise an exception because the joined tables of each queries are different.
Post.by_admin.or(Post.joins(:comments))
```

It can work, when both side use the same joins and only have different conditions.

Since the `#where_assoc_*` methods only add a single `#where`, they are compatible with `#or` and other similar tools.

### Unable to handle recursive associations

When you have recursive associations such as parent/children, you are interacting with the same table twice.

Using `#joins`, `#includes` + `#references`, `#eager_load` automatically create an alias for you. But if you
want to have conditions, this alias can be arcane and will change as you do more such joins. Overall, this
feels complicated and won't work too well in scopes.

The last option is to use raw SQL, [which has problems](#raw-sql-joins-or-sub-selects).

`#where_assoc_*` methods handle this seamlessly. The conditions can use the real table name, so any scope can be used.

### Unable to handle polymorphic belongs_to

When you have a polymorphic belongs_to, you can't use `#joins` or `#includes` in order to do queries on it.
You have to use manual SQL ([raw SQL joins](#raw-sql-joins-or-sub-selects)) or a gem that provides the
feature, such as `activerecord_where_assoc`.

`#where_assoc_*` methods can handle this in 3 ways based on the
[:poly_belongs_to option](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods.html#module-ActiveRecordWhereAssoc::RelationReturningMethods-label-3Apoly_belongs_to+option):
* The default will raise an exception
* You can have the gem do a `#pluck` to auto detect which models to search in, but this can be expensive
* You can specify which models to search in, this has the added benefit of allowing to search for a subset only

### Doesn't compose well

Let's say Posts that have a comment that was reported and a comment that was made by an admin. You have
to be careful, because using `#includes` and `#joins` will instead return Posts what have a comment that is
both reported and made by an admin at the same time.

If you are looking for it to possibly be 2 different comments, then you either need to write the `#joins`
manually or to use simply use the `#where_assoc_*` of this gem.

## ActiveRecord only alternatives

Those are the common ways given in stack overflow answers.

### Using `#joins` and `#where`

```ruby
Post.where_assoc_exists(:comments, is_spam: true)
Post.joins(:comments).where(comments: {is_spam: true})
```

* If the association maps to multiple records (such as with a has_many), then the the relation will return one
record for each matching association record. In this example, you would get the same post twice if it has 2
comments that are marked as spam.
  Using `uniq` can solve this issue, but if you do that in a scope, then that scope unexpectedly adds a DISTINCT
  to your query, which can lead to unexpected results if you actually wanted duplicates for a different reason.

* Doing the opposite is a lot more complicated, as seen below. You have to include your conditions directly in
  the join and use a LEFT JOIN, this means writing the whole thing in raw SQL, and then you must check for the
  id of the association to be empty.

```ruby
Post.where_assoc_not_exists(:comments, is_spam: true)
Post.joins("LEFT JOIN comments ON posts.id = comments.post_id AND comments.is_spam = true").where(comments: {id: nil})
```

Writing a raw join like that has yet more problems: [raw SQL joins](#raw-sql-joins-or-sub-selects)

* If you want to have another condition referring to the same association (or just the same table), then you
  need to write out the SQL for the second join using an alias. Therefore, your scopes are not even compatible
  unless each of them has a join with a unique alias.

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
* [Cannot be used with Rails 5's `#or`](#incompatible-with-or)
* [Treats has_one like a has_many](#treating-has_one-like-has_many)
* [Can't handle recursive associations](#unable-to-handle-recursive-associations)
* [Can't handle polymorphic belongs_to](#unable-to-handle-polymorphic-belongs_to)
* [Doesn't compose well](#doesnt-compose-well)

### Using `#includes` (or `#eager_load`) and `#where`

This solution is similar to the `joins` one above, but avoids the need for `uniq`. Every other problems of the
`joins` remain. You also add other potential issues.

```ruby
Post.where_assoc_exists(:comments, is_spam: true)
Post.eager_load(:comments).where(comments: {is_spam: true})
```

* You are triggering the loading of potentially lots of records that you might not need. You don't expect a
  scope like `have_reported_comments` to trigger eager loading. This is a performance degradation.

* The eager loaded records of the association are actually also filtered by the conditions. All of the posts
  returned will only have the comments that are spam.
  This means if you iterate on `Post.have_reported_comments` to display each of the comments of the posts that
  have at least one reported comment, you are actually only going to display the reported comments. This may
  be what you wanted to do, but it clearly isn't intuitive.

* [Cannot be used with Rails 5's `#or`](#incompatible-with-or)
* [Treats has_one like a has_many](#treating-has_one-like-has_many)
* [Can't handle recursive associations](#unable-to-handle-recursive-associations)
* [Can't handle polymorphic belongs_to](#unable-to-handle-polymorphic-belongs_to)
* [Doesn't compose well](#doesnt-compose-well)

* Simply cannot be used for complex cases.

Note: using `#includes` (or `#eager_load`) already does a LEFT JOIN, so it is pretty easy to do a "not exists",
but only if you don't need any condition on the association (which would normally need to be in the JOIN clause):

```ruby
Post.where_assoc_exists(:comments)
Post.eager_load(:comments).where(comments: {id: nil})
```

### Using `#where("EXISTS( SELECT... )")`

This is what is gem does behind the scene, but doing it manually can lead to troubles:

* Problems with writing [raw SQL sub-selects](#raw-sql-joins-or-sub-selects)

* Unless you do a quite complex nested sub-selects, you will [treat has_one like a has_many](#treating-has_one-like-has_many)


## Alternative gems

### where_exists

https://github.com/EugZol/where_exists

An interesting gem that also does `EXISTS (SELECT ... )` behind the scene. Solves most issues from ActiveRecord
only alternatives, but appears less powerful than where_assoc_exists.

* where_exists supports polymorphic belongs_to only by always doing a `#pluck` everytime. In some situation could
  be a slow query if there is a lots of rows to scan. where_assoc also allows directly specifying the classes
  manually, avoiding the pluck and possibly filtering the choices.

* No shortcut to dig deeper in the associations

```ruby
# with activerecord_where_assoc
User.where_assoc_exists([:posts, :comments])

# with where_exists
User.where_exists(:posts) { |posts| posts.where_exists(comments) }
```

* Has no equivalent to `#where_assoc_count`
```ruby
# There is no equivalent for this (posts with more than 5 comments)
Post.where_assoc_count(:comments, :>, 5)
```

* [Treats has_one like a has_many](#treating-has_one-like-has_many)

* [Can't handle recursive associations](#unable-to-handle-recursive-associations)

* `#where_exists` is shorter than `#where_assoc_exists`, but it is also less obvious about what it does.
  In any case, it is trivial to alias one name to the other one.

* where_exists supports Rails 4.2 and up, while activerecord_where_assoc supports Rails 4.1 and up.
