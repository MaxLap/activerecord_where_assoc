SELECT "users".* FROM "users"
Here are some example usages of the gem, along with the generated SQL.

Each of those methods can be chained with scoping methods, so they can be used on `Post`, `my_user.posts`, `Post.where('hello')` or inside a scope. Note that for the `*_sql` variants, those should preferably be used on classes only, because otherwise, it could be confusing for a reader.

The models can be found in [examples/models.md](examples/models.md). The comments in that file explain how to get a console to try the queries. There are also example uses of the gem for scopes.

The content of this file is generated when running `rake`

-------

## Simple examples

```ruby
# Posts that have a least one comment
Post.where_assoc_exists(:comments)
```
```sql
SELECT "posts".* FROM "posts"
WHERE (EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id"
))
```

---

```ruby
# Posts that have no comments
Post.where_assoc_not_exists(:comments)
```
```sql
SELECT "posts".* FROM "posts"
WHERE (NOT EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id"
))
```

---

```ruby
# Posts that have a least 50 comment
Post.where_assoc_count(50, :<=, :comments)
```
```sql
SELECT "posts".* FROM "posts"
WHERE ((50) <= COALESCE((
  SELECT COUNT(*) FROM "comments"
  WHERE "comments"."post_id" = "posts"."id"
), 0))
```

---

```ruby
# Users that have made posts
User.where_assoc_exists(:posts)
```
```sql
SELECT "users".* FROM "users"
WHERE (EXISTS (
  SELECT 1 FROM "posts"
  WHERE "posts"."author_id" = "users"."id"
))
```

---

```ruby
# Users that have made posts that have comments
User.where_assoc_exists([:posts, :comments])
```
```sql
SELECT "users".* FROM "users"
WHERE (EXISTS (
  SELECT 1 FROM "posts"
  WHERE "posts"."author_id" = "users"."id" AND (EXISTS (
    SELECT 1 FROM "comments"
    WHERE "comments"."post_id" = "posts"."id"
  ))
))
```

---

```ruby
# Users with a post or a comment (without using ActiveRecord's `or` method)
# Using `my_users` to highlight that *_sql methods should always be called on the class
my_users.where("#{User.assoc_exists_sql(:posts)} OR #{User.assoc_exists_sql(:comments)}")
```
```sql
SELECT "users".* FROM "users"
WHERE (EXISTS (
  SELECT 1 FROM "posts"
  WHERE "posts"."author_id" = "users"."id"
) OR EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."author_id" = "users"."id"
))
```

---

```ruby
# Users with a post or a comment (using ActiveRecord's `or` method)
User.where_assoc_exists(:posts).or(User.where_assoc_exists(:comments))
```
```sql
SELECT "users".* FROM "users"
WHERE (EXISTS (
  SELECT 1 FROM "posts"
  WHERE "posts"."author_id" = "users"."id"
) OR EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."author_id" = "users"."id"
))
```

---

## Examples with condition / scope

```ruby
# comments of `my_post` that were made by an admin (Using a hash)
my_post.comments.where_assoc_exists(:author, is_admin: true)
```
```sql
SELECT "comments".* FROM "comments"
WHERE "comments"."post_id" = 1 AND (EXISTS (
  SELECT 1 FROM "users"
  WHERE "users"."id" = "comments"."author_id" AND "users"."is_admin" = 1
))
```

---

```ruby
# comments of `my_post` that were not made by an admin (Using scope)
my_post.comments.where_assoc_not_exists(:author, &:admins)
```
```sql
SELECT "comments".* FROM "comments"
WHERE "comments"."post_id" = 1 AND (NOT EXISTS (
  SELECT 1 FROM "users"
  WHERE "users"."id" = "comments"."author_id" AND "users"."is_admin" = 1
))
```

---

```ruby
# Posts that have at least 5 reported comments (Using array condition)
Post.where_assoc_count(5, :<=, :comments, ["is_reported = ?", true])
```
```sql
SELECT "posts".* FROM "posts"
WHERE ((5) <= COALESCE((
  SELECT COUNT(*) FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND (is_reported = 1)
), 0))
```

---

```ruby
# Posts made by an admin (Using a string)
Post.where_assoc_exists(:author, "is_admin = 't'")
```
```sql
SELECT "posts".* FROM "posts"
WHERE (EXISTS (
  SELECT 1 FROM "users"
  WHERE "users"."id" = "posts"."author_id" AND (is_admin = 't')
))
```

---

```ruby
# comments of `my_post` that were not made by an admin (Using block and a scope)
my_post.comments.where_assoc_not_exists(:author) { admins }
```
```sql
SELECT "comments".* FROM "comments"
WHERE "comments"."post_id" = 1 AND (NOT EXISTS (
  SELECT 1 FROM "users"
  WHERE "users"."id" = "comments"."author_id" AND "users"."is_admin" = 1
))
```

---

```ruby
# Posts that have 5 to 10 reported comments (Using block with #where and range for count)
Post.where_assoc_count(5..10, :==, :comments) { where(is_reported: true) }
```
```sql
SELECT "posts".* FROM "posts"
WHERE (COALESCE((
  SELECT COUNT(*) FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND "comments"."is_reported" = 1
), 0) BETWEEN 5 AND 10)
```

---

```ruby
# comments made in replies to my_user's post
Comment.where_assoc_exists(:post, author_id: my_user.id)
```
```sql
SELECT "comments".* FROM "comments"
WHERE (EXISTS (
  SELECT 1 FROM "posts"
  WHERE "posts"."id" = "comments"."post_id" AND "posts"."author_id" = 1
))
```

---

## Complex / powerful examples

```ruby
# posts with a comment by an admin (uses array to go through multiple associations)
Post.where_assoc_exists([:comments, :author], is_admin: true)
```
```sql
SELECT "posts".* FROM "posts"
WHERE (EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND (EXISTS (
    SELECT 1 FROM "users"
    WHERE "users"."id" = "comments"."author_id" AND "users"."is_admin" = 1
  ))
))
```

---

```ruby
# posts where the author also commented on the post (uses a conditions between tables)
Post.where_assoc_exists(:comments, "posts.author_id = comments.author_id")
```
```sql
SELECT "posts".* FROM "posts"
WHERE (EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND (posts.author_id = comments.author_id)
))
```

---

```ruby
# posts with a reported comment made by an admin (must be the same comments)
Post.where_assoc_exists(:comments, is_reported: true) {
  where_assoc_exists(:author, is_admin: true)
}
```
```sql
SELECT "posts".* FROM "posts"
WHERE (EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND "comments"."is_reported" = 1 AND (EXISTS (
    SELECT 1 FROM "users"
    WHERE "users"."id" = "comments"."author_id" AND "users"."is_admin" = 1
  ))
))
```

---

```ruby
# posts with a reported comment and a comment by an admin (can be different or same comments)
my_user.posts.where_assoc_exists(:comments, is_reported: true)
             .where_assoc_exists([:comments, :author], is_admin: true)
```
```sql
SELECT "posts".* FROM "posts"
WHERE "posts"."author_id" = 1 AND (EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND "comments"."is_reported" = 1
)) AND (EXISTS (
  SELECT 1 FROM "comments"
  WHERE "comments"."post_id" = "posts"."id" AND (EXISTS (
    SELECT 1 FROM "users"
    WHERE "users"."id" = "comments"."author_id" AND "users"."is_admin" = 1
  ))
))
```
```ruby
# Users with more posts than comments
# Using `my_users` to highlight that *_sql methods should always be called on the class
my_users.where("#{User.only_assoc_count_sql(:posts)} > #{User.only_assoc_count_sql(:comments)}")
```
```sql
SELECT "users".* FROM "users"
WHERE (COALESCE((
  SELECT COUNT(*) FROM "posts"
  WHERE "posts"."author_id" = "users"."id"
), 0) > COALESCE((
  SELECT COUNT(*) FROM "comments"
  WHERE "comments"."author_id" = "users"."id"
), 0))
```
