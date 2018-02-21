* Add comments to explain the tests
* Add mutation testing?
* Have a way to customize the way the queries are built.  
  ex: ignore has_one's behavior, place constraints in the nested query, etc.

Doc-wise:
* Add doc on the new methods

Maybe:
* where_assoc_count could receive a relation as first parameter? Needs to make relation_on_association a public API
* Have a way to do some benchmarking to compare different ways to build queries
* Do a test suite that is just simple specs. So different expected behaviors are explained in them?
