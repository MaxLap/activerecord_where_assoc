* Add mutation testing?
* Add a way of doing between for where_assoc_count.
  Passing a range as 1st param and :== or :!= as 2nd
  Post.where_assoc_count(3..6, :==, comments)
  Post.where_assoc_count(3..6, :!=, comments)
* Add a way of handling polymorphic belongs_to. Probably using an option to specify the class to use, or to pluck...

Maybe:
* Have a way to do some benchmarking to compare different ways to build queries?
* Do a test suite that is just simple specs. So different expected behaviors are explained in them?
* Consider writing a html page with js to build queries from checkboxes
* Add explanation of the tests suite. But i'm considering redoing it so...
