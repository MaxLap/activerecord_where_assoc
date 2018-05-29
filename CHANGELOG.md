* It is now possible to pass a `Range` as first argument to `#where_assoc_count`.  
  Ex: Users that have between 10 and 20 posts
  `User.where_assoc_count(10..20, :==, :posts)`
  The operator in that case must be either :== or :!=.  
  This will use `BETWEEN` and `NOT BETWEEN`.  
  Ranges that exclude the last value, i.e. `5...10`, are also supported, resulting in `BETWEEN 5 and 9`.
  Ranges with infinities are also supported.
