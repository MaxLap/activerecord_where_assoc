This is an introduction to the
[activerecord_where_assoc](https://github.com/MaxLap/activerecord_where_assoc) gem. It's a bit long, but that's because
it is quite powerful and I have to explain some problems with the alternative ways of doing what it does.

Rails has a system to interact with your database called ActiveRecord. Its pretty powerful but... did you ever try to
make a query which has a condition based on an association? A simple example would be "I want all the posts that have
comments". This sounds simple, but is actually somewhat tricky to do correctly in ActiveRecord.

The common ways you may find online:
```ruby
Post.joins(:comments)
Post.includes(:comments).references(:comments).where("comments.id IS NOT NULL")
Post.eager_load(:comments).where("comments.id IS NOT NULL")
Post.where("EXISTS(SELECT 1 FROM comments where posts.id = comments.post_id)")
```

But each of these approaches have some side effects that can make things harder for yourself later:
* Using `#joins` will make your query return duplicate entries if a `Post` has multiple `Comments`.<br>
  You might fix that by adding `#distinct` to the query, but that is a change to the whole query which could
  cause issues depending on what else you are doing in the query (maybe you wanted duplicates from another join?).
* Using `#includes` or `#eager_load` will trigger eager-loading of your models.
  * If you don't actually need the `Comments`, this is wasteful.
  * If you use conditions on the comments, the eager-loading will only load the associated records that match.
    If you then use the `comments` relation, it will only return those that matched the condition. This is a
    terrible idea for a scope.
* There is the option of using counter caches, but while that works for very basic cases, it requires setup and
  is not able to deal with more complex needs (conditions and nesting).
* Doing an `EXISTS` query manually is longer and error prone. It's easy to forget a condition and not notice the error
  right away, especially for more complex needs, such as nested queries.

These are just some of the ways of doing it, and some of the problems with them. If you are curious, I made a
[whole document](ALTERNATIVES_PROBLEMS.md) with all the ways and more problems with detailed explanation.

To me, the biggest issues that no alternatives fully solve are:
* Too verbose and error prone
* Your intent is not clear... Are you joining that table because you want to filter based on it or just because you
  need it for ordering or something else?
* Make your scopes have unexpected behaviors... Do you expect your scopes to:
  * make your query return duplicated results?
  * add a `#distinct` to your query?
  * trigger eager-loading?
  * make partial eager-loading of an association, generating subtle bugs?
  * be incompatible with each other?

A scope should filter records and do nothing more. (Unless you want it to do more/something else, but that should be clear)

The root of the problem is that when you want to filter records and do nothing else, the SQL `JOIN` (which is used by
`#joins`, `#includes`, `#eager_load`) is the wrong wrong tool for the job!

A sign that it's the wrong tool is that you can't use it multiple time for the same table without using a unique
name for the table each time. If you have the scopes `#with_recent_comment` and `#with_old_comment`. You can't do
`Post.with_recent_comment.with_old_comment`, because only a single join will be done, so you will be searching
for a single comment that is both old and recent.

```ruby
Post.with_recent_comment.with_old_comment
# using what you find online, your scopes would probably end up generating this (I removed the duplicated joins)
Post.joins(:comments)
    .where("comments.created_at > ?", 5.days.ago)
    .where("comments.created_at <= ?", 5.days.ago)
# or this:
Post.includes(:comments).references(:comments)
    .where("comments.created_at > ?", 5.days.ago)
    .where("comments.created_at <= ?", 5.days.ago)
```

The only way to make the scopes play nice together, is if you use `joins` and write out the SQL for the `JOIN`
with a custom alias for the table unique to that use, and then use that alias in the condition. This is painful and has
many drawbacks. The scopes would look like this:
```ruby
scope :with_old_comment, -> {
  joins("INNER JOIN comments old_comments ON comments.post_id = posts.id")
    .where("old_comments.created_at <= ?", 5.days.ago)
}
```
And since we are using joins, we probably need to use `#distinct`? I'm always uneasy at adding those side-effects to my scopes.
I want them to be as lean as possible, to do what their name imply, nothing more.

I hope you understand that there is no good way of dealing with this in ActiveRecord only. You won't have as much issues
when the condition is on a `#belongs_to`, because there is a single record, so you can't get duplicates, and you
always want to target the same record, so just using `#joins` works fine. But having to choose the way to do things
each time in order to avoid problems gets annoying.

This is why I made the
[activerecord_where_assoc](https://github.com/MaxLap/activerecord_where_assoc)
gem.

You use it like this: `Post.where_assoc_exists(:comments)`

It's almost too simple compared to the built-in ways. Readability-wise it's great, it actually says what it does.
There is no issue of duplicates being returned.

If we go with the more complex example that had conditions on the comments, here's the resulting query:

```ruby
Post.with_recent_comment.with_old_comment
Post.where_assoc_exists(:comments, ["created_at > ?", 5.days.ago])
    .where_assoc_exists(:comments, ["created_at <= ?", 5.days.ago])
# The scope is simply
scope :with_old_comment, -> {
  where_assoc_exists(:comments, ["created_at <= ?", 5.days.ago])
}
```

Basically, you can pass conditions in the second argument. Records of the association that match those conditions are
considered to be "existing". The condition can take multiple forms:

```ruby
Post.where_assoc_exists(:comments, ["created_at <= ?", 5.days.ago])
Post.where_assoc_exists(:comments, is_spam: true)
Post.where_assoc_exists(:comments, "is_spam = true")
```

You may notice I'm not including the table name in those conditions, that's because with the way the query is generated,
it will not be ambiguous even if the `Post` and the `Comment` table have a column with the same name.

If you have more complex conditions, you can pass a block instead
```ruby
Post.where_assoc_exists(:comments) { |comments_scope|
  comments_scope.where("created_at <= ?", 5.days.ago)
}
# If your block has no parameters, then the `self` is the scope,
# so you can be more concise:
Post.where_assoc_exists(:comments) {
  where("created_at <= ?", 5.days.ago)
}

# The main advantage is that now, you can even use the scopes that you have on your comments!
# Imagine the `Comment` model has a scope `old`
Post.where_assoc_exists(:comments) { |comments_scope|
  comments_scope.old
}
# Now those are short and clear:
Post.where_assoc_exists(:comments) { old }
Post.where_assoc_exists(:comments, &:old)
```

Now we can easily reuse scopes and avoid duplicating the logic of what is an old comment!

Since we can run any scoping method in the block, it mean we can also nest them!
```ruby
# Posts that have a comment made by an admin (without using scopes)
Post.where_assoc_exists(:comments) {
  where_assoc_exists(:author, is_admin: true)
}

# If we used scopes, it would probably look like this:
Post.where_assoc_exists(:comments, &:by_admin)
# or like this:
Post.where_assoc_exists(:comments) {
  where_assoc_exists(:author, &:admin)
}
# Depending on which scopes you have in your application
```

But if we go back to that first nesting example, this is something that can be quite common. You want to basically
walk through your associations up to a certain one, and possibly also do a condition on that last one. The gem actually
makes this even easier:

```ruby
Post.where_assoc_exists(:comments) {
  where_assoc_exists(:author, is_admin: true)
}
# Can be written as
Post.where_assoc_exists([:comments, :author], is_admin: true)
```

Basically, you just list the associations you want to walk through and the conditions on the last association (if any,
it could also be a block). The gem will do the nesting for you.

### More

Here is another request: "I want all the posts that *don't* have comments". Doing this with built-in ActiveRecord
methods is left as an exercise. Here is how you can do it now:

```ruby
Post.where_assoc_not_exists(:comments)
```

The `where_assoc_not_exists` is the exact same as `where_assoc_exists`, but it will return records for which none of the
records of the association match the condition

Now lets say you want posts that don't have comments from an admin:

```ruby
# The `not` is only on the first call, not the nested one. That's what you want
Post.where_assoc_not_exists(:comments) {
  where_assoc_exists(:author, is_admin: true)
}
# Can be written as
Post.where_assoc_not_exists([:comments, :author], is_admin: true)
# Or, if you have the admin scope on Author
Post.where_assoc_not_exists([:comments, :author], &:admin)
# Or if you have the by_admin scope on Comment
Post.where_assoc_not_exists(:comments, &:by_admin)
```

### More problems with the alternatives

Lets say your association is a `has_one`, and it can have multiple records. In that case, `has_one` will return the `first`
record it finds. (When you do that, you need an `order` clause) In that case, using `joins` or `includes` will query as
if you had a `has_many`, so if any of the "other" associated records match, you will will get a result. `where_assoc_*`
does not do that, it generates the extra SQL to treat the `has_one` correctly.

What about recursive relations such as having a parent/children relation. When you `joins` or `includes`, since it's on
the same table, then ActiveRecord will do an SQL alias for the table name. So now you must use that alias in your conditions,
making things less clear (and if you forget, you won't get an error, just a bad behavior). `where_assoc_*` does not create
an alias, you cannot accidentally target the wrong level of abstraction.

### Even more

Yet another request: "I want all the posts with at least 5 comments". This isn't a need that happens often,
sometimes it's more of a curiosity that you want to query once. In any case, doing this in ActiveRecord
(without just loading everything) is a nightmare, especially when you want to nest through multiple associations.

```ruby
Post.where_assoc_count(:comments, :>=, 5)
```

This is a more powerful version of `#where_assoc_exists` / `#where_assoc_not_exists`. You can specify how many
records in the association must match for a record to be returned.

Again, lets say we want posts with at least 5 comments by admin:

```ruby
Post.where_assoc_count(:comments, :>=, 5) {
  where_assoc_exists(:author, is_admin: true)
}
# Or if you have the by_admin scope on Comment
Post.where_assoc_count(:comments, :>=, 5, &:by_admin)
```

You can use any of the basic operators: `:<`, `:<=`, `:==`, `:!=`, `:>=`, `:>`. You can even give it a range
instead of a fixed number. See the
[documentation](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/RelationReturningMethods.html#method-i-where_assoc_count)
for details.

### Playing with the SQL

Sometimes, it may happen that you want only to have the SQL for one of these. Maybe you are building a more
complex query, or maybe you need them for an even more complex condition. These are the building blocks for the SQL.

* `assoc_exists_sql` returns only the SQL for doing an EXISTS condition
* `assoc_not_exists_sql` returns only the SQL for doing a NOT EXISTS condition
* `compare_assoc_count_sql` returns only the SQL for doing a condition on the number of associated records that match
* `only_assoc_count_sql` returns only the SQL to count the number of associated records that match, this is to be used in a condition

You can read about them in the [documentation](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/SqlReturningMethods.html). Here is a quick example:

```ruby
User.where("#{User.assoc_exists_sql(:posts)} OR #{User.assoc_exists_sql(:comments)}")
```

### Do you need all of this?

At my work, we have used a WIP version of this gem for many years now. We have more than 250 calls to these methods,
and there would be many more if we had this earlier. The app has 40k lines of code (views excluded). So clearly, this
is a need that can happen frequently.

I also often use these when I have a question about by database. Does *X* ever happen? Lets check, the query
is easy to make in a console now. You can also use the usual `to_sql` to get the powerful SQL query when you need
to do an EXISTS in SQL.

Scopes really become a more powerful tool and allow for more code reuse.

There are more problems I didn't mention here. Handling polymorphic `belongs_to`, interaction with `#or`. This
[whole document](ALTERNATIVES_PROBLEMS.md) details those problems. They are solved by this gem.

If after reading this, you still aren't interested in the gem / aren't going to use this, I would really like to know why.
Please leave me some feedback in [this issue](https://github.com/MaxLap/activerecord_where_assoc/issues/3).

Here is the link to the gem: [activerecord_where_assoc](https://github.com/MaxLap/activerecord_where_assoc)
