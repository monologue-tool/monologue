extends GdUnitTestSuite

## Transactions turn N edits into one undo step, which is what makes editing a whole
## selection at once bearable.

var _history: CommandManager
var _registry: MonologueRegistry


func before_test() -> void:
	_history = CommandManager.new()
	_registry = MonologueRegistry.get_instance()


func _new_variable() -> CollectionItem:
	return _registry.create_collection_item("variables", _history)


func test_a_lone_command_is_its_own_undo_step() -> void:
	_new_variable().set_property_value("name", "health")

	assert_int(_history.get_history_count()).is_equal(1)


func test_a_transaction_collapses_several_commands_into_one_step() -> void:
	var first: CollectionItem = _new_variable()
	var second: CollectionItem = _new_variable()
	var third: CollectionItem = _new_variable()

	var transaction: CommandTransaction = _history.begin("Rename three")
	first.set_property_value("description", "a")
	second.set_property_value("description", "a")
	third.set_property_value("description", "a")
	transaction.commit()

	assert_int(_history.get_history_count()).is_equal(1)
	assert_str(first.get_property_value("description")).is_equal("a")
	assert_str(third.get_property_value("description")).is_equal("a")


func test_undoing_a_transaction_takes_back_all_of_it() -> void:
	var first: CollectionItem = _new_variable()
	var second: CollectionItem = _new_variable()

	var transaction: CommandTransaction = _history.begin("Describe both")
	first.set_property_value("description", "a")
	second.set_property_value("description", "a")
	transaction.commit()

	_history.undo()

	assert_str(first.get_property_value("description")).is_not_equal("a")
	assert_str(second.get_property_value("description")).is_not_equal("a")


func test_nested_transactions_commit_once() -> void:
	# UndoRedo cannot nest create_action(), so the depth counter has to absorb this.
	var variable: CollectionItem = _new_variable()

	var outer: CommandTransaction = _history.begin("outer")
	var inner: CommandTransaction = _history.begin("inner")
	variable.set_property_value("description", "a")
	inner.commit()
	assert_bool(_history.is_in_transaction()).is_true()
	outer.commit()

	assert_bool(_history.is_in_transaction()).is_false()
	assert_int(_history.get_history_count()).is_equal(1)


func test_committing_twice_changes_nothing() -> void:
	var variable: CollectionItem = _new_variable()
	var transaction: CommandTransaction = _history.begin("once")
	variable.set_property_value("description", "a")
	transaction.commit()

	transaction.commit()

	assert_bool(transaction.is_open()).is_false()
	assert_int(_history.get_history_count()).is_equal(1)
