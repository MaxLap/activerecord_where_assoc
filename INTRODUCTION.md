This is meant to be an introduction to the
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
```

But each of these approaches have some side effects that can make things harder for yourself later:
* Using `#joins` will make your query return duplicate entries if a `Post` has multiple `Comments`.  
  You might fix that by adding `#distinct` to the query, but that is a change to the whole query which could
  cause issues depending on what else you are doing.
* Using `#includes` or `#eager_load` will trigger eager-loading of your models.
  * If you don't actually need the `Comments`, this is wasteful.
  * If you use conditions on the comments, the eager-loading will only load the associated records that match.
    If you then use the `comments` relation, it will only return those that matched the condition. This is a
    terrible idea for a scope.
* There is the option of using counter caches, but while that works for very basic cases, it requires setup and
  is not able to deal with more complex needs (conditions and nesting).

These are just some of the ways of doing it, and some of the problems with them. If you are curious, I made a
[whole document](ALTERNATIVES_PROBLEMS.md) with all the ways and more problems with detailed explanation.

To me, the biggest issues that no alternatives fully solve are:
* Too verbose
* Not clear on your intent  
  Are you joining that table because you want to filter based on it or just becasue you need it for ordering or something else?
* Make your scopes have unexpected behaviors
  * Do you expect your scope to make your query return duplicated results?
  * Do you expect your scope to add a `#distinct` to your query?
  * Do you expect your scope to trigger eager-loading?
  * Do you expect your scope make partial eager-loading of an association, generating subtle bugs?
  * And more! See below.

A scope should filter records and do nothing more. (Unless you want it to do more/something else, but that should be clear)

The root of the problem is that when you want to filter records and do nothing else, the SQL `JOIN` (which is used by `#joins`, `#includes`, `#eager_load`) is the wrong wrong tool for the job!

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
with a custom alias for the table unique to that use, and then use that alias in the condition. This is painful and has many drawbacks. The scopes would look like this:
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

Basically, you can pass conditions in the second argument. Those must be matched in for an association to be
considered as "existing". It can take multiple forms:

```ruby
where_assoc_exists(:comments, ["created_at <= ?", 5.days.ago])
where_assoc_exists(:comments, is_spam: true)
where_assoc_exists(:comments, "is_spam = true")
```

You may notice I'm not including the table name in those conditions, that's because with the way the query is generated,
it will not be ambiguous.

If you have more complex conditions, you can pass a block instead
```ruby
where_assoc_exists(:comments) { |comments_scope|
  comments_scope.where("created_at <= ?", 5.days.ago)
}
# If your block has no parameters, then the `self` is the scope,
# so you can be more concise:
where_assoc_exists(:comments) {
  where("created_at <= ?", 5.days.ago)
}

# The main advantage is that now, you can even use the scopes that you have on your comments!
# Imagine the `Comment` model has a scope `old`
where_assoc_exists(:comments) { |comments_scope|
  comments_scope.old
  }
# Now those are short and clear:
where_assoc_exists(:comments) { old }
where_assoc_exists(:comments, &:old)
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

The `where_assoc_not_exists` is the exact same as `where_assoc_exists`, but it will return records for which
no association record exists that match the condition.

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

### Even more

Yet another request: "I want all the posts with at least 5 comments". This isn't a need that happens often,
sometimes it's more of a curiosity that you want to query once. In any case, doing this in ActiveRecord
(without just loading everything) is a nightmare, especially when you want to nest through multiple associations.

```ruby
Post.where_assoc_count(5, :<=, :comments)
```

This is a more powerful version of `#where_assoc_exists` / `#where_assoc_not_exists`. You can specify how many
records in the association must match for a record to be returned.

Again, lets say we want posts with at least 5 comments by admin:

```ruby
Post.where_assoc_count(5, :<=, :comments) {
  where_assoc_exists(:author, is_admin: true)
}
# Or if you have the by_admin scope on Comment
Post.where_assoc_count(5, :<=, :comments, &:by_admin)
```

The order of the parameters may seem confusing. But you will get used to it. It helps to remember that the
goal is to do: `5 < (SELECT COUNT(*) FROM ...)`. So the parameters are in the same order as in that query:
number, operator, association.

You can use any of the basic operators: `:<`, `:<=`, `:==`, `:!=`, `:>=`, `:>`. You can even give it a range
instead of a fixed number. See the
[documentation](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/QueryMethods.html#method-i-where_assoc_count)
for details.

### Do you need this?

At my work, we have used a WIP version of this gem for many years now. We have more than 250 calls to these methods,
and there would be many more if we had this earlier. The app has 40k lines of code (views excluded). So clearly, this
is a need that can happen frequently.

I also often use these when I have a question about by database. Does *X* ever happen? Lets check, the query
is easy to make in a console now.

Scopes really become a more powerful tool and allow for more code reuse.

There are many other problems I didn't mention here. Handling `has_one` correctly (not like a `has_many`), handling
recursive associations, handling polymorphic belongs_to, works with `#or`. I made a [whole document](ALTERNATIVES_PROBLEMS.md)
with details of those solved problems.

If after reading this, you still aren't interested in the gem / aren't going to use this, I would really like to know why.
Please leave me some feedback in [this issue](https://github.com/MaxLap/activerecord_where_assoc/issues/3).

Here is the link to the gem: [activerecord_where_assoc](https://github.com/MaxLap/activerecord_where_assoc)
