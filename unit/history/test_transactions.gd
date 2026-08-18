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


func test_a_transaction_is_one_step_however_many_edits_went_into_it() -> void:
	var first: CollectionItem = _new_variable()
	var second: CollectionItem = _new_variable()

	# On its own, an edit is already its own step.
	first.set_property_value("name", "health")
	assert_int(_history.get_history_count()).is_equal(1)

	var transaction: CommandTransaction = _history.begin("Describe both")
	first.set_property_value("description", "a")
	second.set_property_value("description", "a")
	transaction.commit()

	assert_int(_history.get_history_count()).is_equal(2)
	assert_str(first.get_property_value("description")).is_equal("a")

	_history.undo()

	assert_str(first.get_property_value("description")).is_not_equal("a")
	assert_str(second.get_property_value("description")).is_not_equal("a")


func test_a_transaction_closes_once_however_deep_it_was_opened() -> void:
	# UndoRedo cannot nest create_action(), so the depth counter has to absorb this.
	var variable: CollectionItem = _new_variable()

	var outer: CommandTransaction = _history.begin("outer")
	var inner: CommandTransaction = _history.begin("inner")
	variable.set_property_value("description", "a")
	inner.commit()
	assert_bool(_history.is_in_transaction()).is_true()

	outer.commit()
	outer.commit()

	assert_bool(_history.is_in_transaction()).is_false()
	assert_bool(outer.is_open()).is_false()
	assert_int(_history.get_history_count()).is_equal(1)


func test_a_project_nobody_has_touched_has_nothing_to_undo() -> void:
	# A template builds through the same commands an edit does. Left as it lands, a new
	# project reads as unsaved work and its first Ctrl+Z takes apart what it was born with.
	var project: MonologueProject = auto_free(MonologueProject.new())

	# Counted rather than only checked at the end: the window title is painted from each of
	# these as it arrives, so one reported during construction leaves a star behind whatever
	# the flag says afterwards.
	var reported: Array[int] = [0]
	project.undo_redo_changed.connect(func() -> void: reported[0] += 1)
	await project.ready

	assert_int(reported[0]).override_failure_message(
		"Building the project reported %d edits nobody made." % reported[0]
	).is_equal(0)
	assert_bool(project.is_dirty).override_failure_message(
		"A project arrived with changes nobody made."
	).is_false()
	assert_bool(project.command_manager.can_undo()).override_failure_message(
		"A new project's first undo would take apart its own template."
	).is_false()

	# And the first real edit is still one step, undoable back to how the project arrived.
	var born_with: Variant = project.manifest.get_property_value("entry_point")
	project.manifest.set_property_value("entry_point", "storyline-ELSEWHERE")

	assert_bool(project.is_dirty).override_failure_message(
		"An edit did not mark the project as changed."
	).is_true()
	assert_bool(project.command_manager.undo()).is_true()
	assert_that(project.manifest.get_property_value("entry_point")).is_equal(born_with)
	assert_bool(project.command_manager.can_undo()).override_failure_message(
		"Undoing the one edit made left something behind it."
	).is_false()

