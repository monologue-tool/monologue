extends GdUnitTestSuite

## Exercises the schema DSL through a real collection item, with no editor booted:
## a CommandManager and an item is all it takes.

var _history: CommandManager


func before_test() -> void:
	_history = CommandManager.new()


func _new_variable() -> CollectionItem:
	return MonologueRegistry.get_instance().create_collection_item("variables", _history)


func test_an_object_can_be_built_without_a_scene_tree() -> void:
	var variable: CollectionItem = _new_variable()

	assert_object(variable).is_not_null()
	assert_object(variable.get_property("name")).is_not_null()
	assert_object(variable.get_property("type")).is_not_null()


func test_every_object_gets_a_type_prefixed_id() -> void:
	var variable: CollectionItem = _new_variable()
	var id: String = variable.get_property_value("id")

	assert_str(id).starts_with("%s-" % variable.get_type())


func test_two_objects_of_one_type_get_different_ids() -> void:
	assert_str(_new_variable().get_property_value("id")).is_not_equal(
		_new_variable().get_property_value("id")
	)


func test_declared_settings_survive_onto_the_property() -> void:
	var name_property: Property = _new_variable().get_property("name")

	assert_bool(name_property.get_settings_value(PropertySettings.KEY_REQUIRED, false)).is_true()
	assert_bool(name_property.get_settings_value(PropertySettings.KEY_UNIQUE, false)).is_true()


func test_a_declaration_path_places_the_property_in_its_category() -> void:
	var variable: CollectionItem = _new_variable()

	# Declared as "extra/description".
	assert_str(variable.get_property("description").get_category()).is_equal("Extra")
	# Declared as a bare name, so it lands in General.
	assert_str(variable.get_property("type").get_category()).is_equal("General")


func test_properties_are_frozen_once_the_object_is_built() -> void:
	# Guards against a node mutating its own schema at runtime, which would make one
	# instance's settings diverge from every other instance of the same type.
	var variable: CollectionItem = _new_variable()

	assert_bool(variable.get_property("name").is_frozen()).is_true()


func test_a_node_declares_exactly_one_main_property() -> void:
	var sentence: InspectableNode = MonologueRegistry.get_instance().create_node(
		"sentence", _history
	)

	var main_properties: Array[Property] = []
	for property: Property in sentence.get_properties():
		if property.is_main_property():
			main_properties.append(property)

	assert_int(main_properties.size()).is_equal(1)
	assert_str(main_properties[0].name).is_equal("sentence")
	assert_object(sentence.get_main_property()).is_same(main_properties[0])


func test_a_nodes_own_properties_are_frozen_too() -> void:
	# color / notes / position are declared by InspectableNode before super._init(),
	# which is what puts them inside the freeze pass.
	var sentence: InspectableNode = MonologueRegistry.get_instance().create_node(
		"sentence", _history
	)

	for property_name: String in ["color", "notes", "position", "id"]:
		(
			assert_bool(sentence.get_property(property_name).is_frozen())
			. override_failure_message("Property '%s' escaped the freeze pass." % property_name)
			. is_true()
		)


func test_two_instances_do_not_share_a_settings_dictionary() -> void:
	var first: CollectionItem = _new_variable()
	var second: CollectionItem = _new_variable()

	first.get_property("name").set_settings_value(PropertySettings.KEY_READ_ONLY, true)

	(
		assert_bool(
			second.get_property("name").get_settings_value(PropertySettings.KEY_READ_ONLY, false)
		)
		. is_false()
	)


func test_setting_a_value_goes_through_the_undo_history() -> void:
	var variable: CollectionItem = _new_variable()

	variable.set_property_value("name", "health")

	assert_str(variable.get_property_value("name")).is_equal("health")
	assert_bool(_history.undo_redo.has_undo()).is_true()

	_history.undo_redo.undo()
	assert_str(variable.get_property_value("name")).is_not_equal("health")


func test_setting_the_same_value_records_nothing() -> void:
	var variable: CollectionItem = _new_variable()
	var current: Variant = variable.get_property_value("name")

	variable.set_property_value("name", current)

	assert_bool(_history.undo_redo.has_undo()).is_false()


func test_changing_a_value_announces_the_property_name() -> void:
	var variable: CollectionItem = _new_variable()
	var monitor: Object = monitor_signals(variable)

	variable.set_property_value("name", "gold")

	await assert_signal(monitor).is_emitted("property_changed", ["name"])


func test_an_object_round_trips_through_a_dictionary() -> void:
	var original: CollectionItem = _new_variable()
	original.set_property_value("name", "gold")
	original.set_property_value("type", "int")

	var restored: CollectionItem = _new_variable()
	restored._from_dict(original._to_dict())

	assert_str(restored.get_property_value("name")).is_equal("gold")
	assert_str(restored.get_property_value("type")).is_equal("int")
	assert_str(restored.get_property_value("id")).is_equal(original.get_property_value("id"))


func test_the_serialised_form_records_the_object_type() -> void:
	var variable: CollectionItem = _new_variable()

	assert_str(variable._to_dict()["$type"]).is_equal(variable.get_type())
