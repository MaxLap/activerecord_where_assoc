* test passing conditions / blocks to where_relation_exists / count
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
* Test things that are expected to fail. (Missing assoc, abstract_table, polymorphic on belongs_to)
* Add check for rails head to travis-ci, somehow? Would be nice to do like with ruby-head. I know changes will make this fail in 5.2

Doc-wise:
* Discuss Rails versions.
* Add doc on the new methods
