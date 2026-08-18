extends GdUnitTestSuite

## Exercises the schema DSL through a real collection item, with no editor booted:
## a CommandManager and an item is all it takes.

var _history: CommandManager


func before_test() -> void:
	_history = CommandManager.new()


func _new_variable() -> CollectionItem:
	return MonologueRegistry.get_instance().create_collection_item("variables", _history)


func test_an_object_arrives_identified_and_frozen_with_what_it_declared() -> void:
	var variable: CollectionItem = _new_variable()
	assert_str(variable.get_property_value("id")).is_not_equal(
		_new_variable().get_property_value("id")
	)

	var declared: Property = variable.get_property("name")
	assert_bool(declared.get_settings_value(PropertySettings.KEY_REQUIRED, false)).is_true()
	assert_bool(declared.get_settings_value(PropertySettings.KEY_UNIQUE, false)).is_true()

	# Freezing guards against an object mutating its own schema at runtime, which would make
	# one instance's settings diverge from every other instance of the same type. The
	# properties InspectableNode declares before super._init() are inside the pass too.
	var sentence: InspectableNode = MonologueRegistry.get_instance().create_node(
		"sentence", _history
	)
	var frozen: Array[Property] = [declared]
	frozen.append_array(sentence.get_properties())
	for property: Property in frozen:
		assert_bool(property.is_frozen()).override_failure_message(
			"Property '%s' escaped the freeze pass." % property.name
		).is_true()


func test_two_instances_do_not_share_a_settings_dictionary() -> void:
	var first: CollectionItem = _new_variable()
	var second: CollectionItem = _new_variable()

	first.get_property("name").set_settings_value(PropertySettings.KEY_READ_ONLY, true)

	assert_bool(
		second.get_property("name").get_settings_value(PropertySettings.KEY_READ_ONLY, false)
	).is_false()


func test_writing_a_value_goes_through_the_history_and_announces_itself() -> void:
	var variable: CollectionItem = _new_variable()
	var monitor: Object = monitor_signals(variable)

	variable.set_property_value("name", "health")

	assert_str(variable.get_property_value("name")).is_equal("health")
	assert_signal(monitor).is_emitted("property_changed", ["name"])
	assert_bool(_history.undo_redo.has_undo()).is_true()

	_history.undo_redo.undo()
	assert_str(variable.get_property_value("name")).is_not_equal("health")

	# Writing what is already there is not a change, so it costs no undo step. On a history
	# of its own: the one above already has something in it.
	var quiet: CommandManager = CommandManager.new()
	var untouched: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"variables", quiet
	)
	untouched.set_property_value("name", untouched.get_property_value("name"))

	assert_bool(quiet.undo_redo.has_undo()).is_false()


func test_an_object_round_trips_with_its_values_and_its_overrides() -> void:
	var original: CollectionItem = _new_variable()
	original.set_property_value("name", "gold")
	original.set_property_value("type", "int")
	original.get_property("name").set_settings_value(PropertySettings.KEY_EXPOSED, true)

	var written: Dictionary = original._to_dict()

	# No wrapper object: a property name maps straight to what it holds, and the user's own
	# choices live in one map beside the values rather than in each value's slot.
	assert_str(written["$type"]).is_equal(original.get_type())
	assert_str(written["name"]).is_equal("gold")
	var overrides: Dictionary = written[InspectableObject.EDITOR_SETTINGS_KEY]
	assert_bool(overrides["name"][PropertySettings.KEY_EXPOSED]).is_true()

	var restored: CollectionItem = _new_variable()
	restored._from_dict(written)

	assert_str(restored.get_property_value("name")).is_equal("gold")
	assert_str(restored.get_property_value("type")).is_equal("int")
	assert_str(restored.get_property_value("id")).is_equal(original.get_property_value("id"))
	assert_bool(
		restored.get_property("name").get_settings_value(PropertySettings.KEY_EXPOSED)
	).is_true()
