* travis
* code climate?
* where_assoc_count tests for has_many (and the others)
* where_assoc_count should use = when passed :==
* test passing conditions / blocks to where_relation_exists
* run tests on postgresql and mysql. The setup is already there and maybe working.
* handle has_one (and tests)
* handle belongs_to (and tests)
* handle has_and_belongs_to_many (and tests)
* handle polymorphism
* handle limit & order in the default_scope, association's scope, has_one. Note that limit in the custom conditions (2nd parameter and block) don't need such consideration.
* where_assoc_count could receive a relation as first parameter
* receive a proc as condition argument, same behavior as passing a block
* receiving a proc/block that takes no argument will use instance_eval on scope
* require applications to enable support for receiving a relation as condition.
* Add comments to explain the tests

* Does LHEW applies when doing joins? If not, this is really broken! This might help the argument of removing this behavior.


Doc-wise:
* Discuss Rails versions.
* Add doc on the new methods
