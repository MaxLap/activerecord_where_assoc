* where_assoc_count is wrong for all but direct association (no through, no path).
  Should do SUM(SUM(SUM(COUNT)))
* where_assoc_count tests for has_many (and the others)
* where_assoc_count should use = when passed :==
* test passing conditions / blocks to where_relation_exists
* handle has_one (and tests)
* handle belongs_to (and tests)
* handle has_and_belongs_to_many (and tests)
* handle polymorphism
* where_assoc_count could receive a relation as first parameter?
* receive a proc as condition argument, same behavior as passing a block
* receiving a proc/block that takes no argument will use instance_exec on scope
* require applications to enable support for receiving a relation as condition.
* Add comments to explain the tests
* Add mutation testing?

* Does LHEW applies when doing joins? If not, this is really broken! This might help the argument of removing this behavior.


Doc-wise:
* Discuss Rails versions.
* Add doc on the new methods
