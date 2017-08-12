* handle polymorphism
* where_assoc_count could receive a relation as first parameter?
* Add comments to explain the tests
* Add mutation testing?
* Have a way to customize the way the queries are built. ex: ignore has_one's behavior, place constraints in the nested query, etc.
* Should there be support for limit on the scopes/default_scope? It's kind of a generalization of has_one's behavior.
* Does LHEW applies when doing joins? If not, this is really broken! This might help the argument of removing this behavior.
* Test things that are expected to fail. (Missing assoc, abstract_table, polymorphic on belongs_to)
* Have a way to do some benchmarking to compare different ways to build queries

Doc-wise:
* Discuss Rails versions.
* Add doc on the new methods
