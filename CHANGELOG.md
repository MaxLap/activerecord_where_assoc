# Unreleased

# 1.1.5 - 2024-05-18

* Add compatibility for Rails 7.2

# 1.1.4 - 2023-10-10

* Add compatibility for Rails 7.1

# 1.1.3 - 2022-08-16

* Add support for associations defined on abstract models

# 1.1.2 - 2020-12-24

* Add compatibility for Rails 6.1

# 1.1.1 - 2020-04-13

* Fix handling for ActiveRecord's NullRelation (MyModel.none) in block and association's conditions.

# 1.1.0 - 2020-02-24

* Added methods which return the SQL used by this gem: `assoc_exists_sql`, `assoc_not_exists_sql`, `compare_assoc_count_sql`, `only_assoc_count_sql`  
  [Documentation for them](https://maxlap.github.io/activerecord_where_assoc/ActiveRecordWhereAssoc/SqlReturningMethods.html)

# 1.0.1

* Fix broken urls in error messages 

# 1.0.0

* Now supports polymorphic belongs_to

# 0.1.3

* Use `SELECT 1` instead of `SELECT 0`...  
  ... it just seems more natural that way.
* Bugfixes

# 0.1.2

* It is now possible to pass a `Range` as first argument to `#where_assoc_count`.  
  Ex: Users that have between 10 and 20 posts
  `User.where_assoc_count(10..20, :==, :posts)`
  The operator in that case must be either :== or :!=.  
  This will use `BETWEEN` and `NOT BETWEEN`.  
  Ranges that exclude the last value, i.e. `5...10`, are also supported, resulting in `BETWEEN 5 and 9`.
  Ranges with infinities are also supported.
