# gdlint: disable=max-public-methods
extends GdUnitTestSuite

## References point at ids, never at names. These are the guarantees that buys:
## renaming a target keeps every reference, and deleting one breaks them visibly
## rather than pointing them somewhere else.

const CHARACTERS: String = "characters"
const VARIABLES: String = "variables"

var _project: MonologueProject


func before_test() -> void:
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project


func after_test() -> void:
	ProjectManager.current_project = null


func _add_item(collection_name: String, values: Dictionary) -> String:
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		collection_name, _project.command_manager
	)
	for property_name: String in values:
		item.set_property_value(property_name, values[property_name])

	var collection: CollectionDocument = _project.get_collection(collection_name)
	var items: Array = collection.get_value().duplicate(true)
	items.append(item._to_dict())
	collection.set_property_value(collection_name, items)

	return str(item.get_property_value("id"))


func _set_item_value(collection_name: String, item_id: String, key: String, value: Variant) -> void:
	var collection: CollectionDocument = _project.get_collection(collection_name)
	var items: Array = collection.get_value().duplicate(true)
	for item: Dictionary in items:
		if _read_id(item) == item_id:
			item[key] = {"value": value}
	collection.set_property_value(collection_name, items)


func _remove_item(collection_name: String, item_id: String) -> void:
	var collection: CollectionDocument = _project.get_collection(collection_name)
	var items: Array = collection.get_value().duplicate(true)
	var kept: Array = []
	for item: Dictionary in items:
		if _read_id(item) != item_id:
			kept.append(item)
	collection.set_property_value(collection_name, kept)


func _first_node(node_type: String) -> InspectableNode:
	for node: InspectableNode in _project.storylines[0].nodes:
		if node.get_type() == node_type:
			return node
	return null


func _issue_codes() -> Array[StringName]:
	var codes: Array[StringName] = []
	for issue: ValidationIssue in _project.validate().issues:
		codes.append(issue.code)
	return codes


static func _read_id(item: Dictionary) -> String:
	var raw: Variant = item.get("id")
	return str((raw as Dictionary).get("value", "")) if raw is Dictionary else ""


func test_renaming_a_character_does_not_break_its_references() -> void:
	var alice_id: String = _add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", alice_id)

	_set_item_value(CHARACTERS, alice_id, "name", "Alicia")

	assert_str(str(sentence.get_property_value("speaker"))).is_equal(alice_id)
	assert_str(
		ReferenceResolver.resolve_label(_project, CHARACTERS, alice_id, sentence)
	).is_equal("Alicia")


func test_two_characters_sharing_a_name_stay_distinguishable() -> void:
	var first_id: String = _add_item(CHARACTERS, {"name": "Twin"})
	var second_id: String = _add_item(CHARACTERS, {"name": "Twin"})

	assert_str(first_id).is_not_equal(second_id)
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, first_id)).is_true()
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, second_id)).is_true()


func test_unresolvable_id_never_resolves_to_a_different_object() -> void:
	_add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", "character-NOTHERE1")

	assert_str(ReferenceResolver.resolve_label(_project, CHARACTERS, "character-NOTHERE1")).is_empty()
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, "character-NOTHERE1")).is_false()
	# The value is kept exactly as it was, so restoring the target repairs it.
	assert_str(str(sentence.get_property_value("speaker"))).is_equal("character-NOTHERE1")


func test_a_dangling_reference_is_reported() -> void:
	var alice_id: String = _add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", alice_id)

	_remove_item(CHARACTERS, alice_id)

	assert_array(_issue_codes()).contains([&"dangling_reference"])
	assert_str(str(sentence.get_property_value("speaker"))).is_equal(alice_id)


func test_the_reverse_index_finds_who_points_at_a_character() -> void:
	var alice_id: String = _add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", alice_id)

	var referrers: Array[ReferenceSite] = _project.get_object_registry().get_referrers(alice_id)

	assert_int(referrers.size()).is_equal(1)
	assert_str(referrers[0].owner_id).is_equal(sentence.get_id())
	assert_str(referrers[0].property_name).is_equal("speaker")


func test_undoing_a_delete_restores_the_reference() -> void:
	var alice_id: String = _add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", alice_id)

	_remove_item(CHARACTERS, alice_id)
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, alice_id)).is_false()

	_project.command_manager.undo()

	# The id never changed, so bringing the character back is all it takes.
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, alice_id)).is_true()
	assert_str(str(sentence.get_property_value("speaker"))).is_equal(alice_id)


func test_undoing_a_node_delete_restores_its_connections() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var sentence: InspectableNode = _first_node("sentence")
	var _before: Array[Dictionary] = sentence.get_main_property().connected_from.duplicate(true)
	assert_array(_before).is_not_empty()

	var command: DeleteNodesCommand = DeleteNodesCommand.new(storyline.id, [_first_node("root")])
	_project.command_manager.execute(command)

	assert_array(sentence.get_main_property().connected_from).is_empty()

	_project.command_manager.undo()

	assert_array(sentence.get_main_property().connected_from).is_equal(_before)


func test_id_collision_is_detected_and_a_fresh_id_is_allocated() -> void:
	var registry: ProjectObjectRegistry = ProjectObjectRegistry.new()

	var first: String = registry.allocate_id("character", "character-DUPLICAT")
	var second: String = registry.allocate_id("character", "character-DUPLICAT")

	assert_str(first).is_equal("character-DUPLICAT")
	assert_str(second).is_not_equal(first)
	assert_bool(second.begins_with("character-")).is_true()


func test_registering_a_taken_id_rewrites_the_object() -> void:
	var registry: ProjectObjectRegistry = ProjectObjectRegistry.new()
	var first: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		CHARACTERS, _project.command_manager
	)
	var twin: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		CHARACTERS, _project.command_manager
	)
	twin.get_property("id").value = first.get_property_value("id")

	registry.register(first)
	registry.register(twin)

	assert_str(str(twin.get_property_value("id"))).is_not_equal(str(first.get_property_value("id")))
	assert_object(registry.get_object(str(first.get_property_value("id")))).is_same(first)
	assert_object(registry.get_object(str(twin.get_property_value("id")))).is_same(twin)


func test_generated_ids_carry_their_type_and_use_the_readable_alphabet() -> void:
	var generated: String = IDGen.generate_object_id("sentence")
	var suffix: String = generated.trim_prefix("sentence-")

	assert_str(generated).starts_with("sentence-")
	assert_int(suffix.length()).is_equal(IDGen.DEFAULT_LENGTH)
	for character: String in suffix:
		assert_bool(IDGen.ALPHABET.contains(character)).override_failure_message(
			"'%s' is not a Crockford base32 character." % character
		).is_true()


func test_reference_ports_are_typed_by_what_they_point_at() -> void:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	var characters: int = registry.get_reference_type_id(CHARACTERS)
	var beziers: int = registry.get_reference_type_id("beziers")

	assert_int(characters).is_greater(0)
	assert_int(characters).is_not_equal(beziers)
	# Asking twice gives the same port, or a link would stop matching on redraw.
	assert_int(registry.get_reference_type_id(CHARACTERS)).is_equal(characters)
	assert_bool(registry.is_compatible(characters, beziers)).override_failure_message(
		"A character reference must not accept a bezier reference."
	).is_false()


func test_a_reference_port_never_shares_an_id_with_a_field_port() -> void:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	var scope_id: int = registry.get_reference_type_id("locations")

	for indexer: MonologueIndexer in registry.list(MonologueObjectType.FIELD):
		assert_int((indexer as FieldIndexer).type_id).is_not_equal(scope_id)


func test_new_items_are_born_with_a_unique_name() -> void:
	var first: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		VARIABLES, _project.command_manager
	)
	var second: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		VARIABLES, _project.command_manager
	)

	assert_str(str(first.get_property_value("name"))).is_not_equal(
		str(second.get_property_value("name"))
	)


func test_a_generated_variable_name_is_a_valid_identifier() -> void:
	var variable: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		VARIABLES, _project.command_manager
	)

	assert_bool(str(variable.get_property_value("name")).is_valid_identifier()).is_true()


func test_deleting_a_variable_does_not_degrade_the_condition_silently() -> void:
	var variable_id: String = _add_item(VARIABLES, {"name": "trust", "type": "int"})
	var option: InspectableNode = _first_node("option")
	option.set_property_value("enable_condition", true)
	option.set_property_value(
		"condition", {"variable": variable_id, "operator": ">=", "value": 3}
	)

	var referrers: Array[ReferenceSite] = _project.get_object_registry().get_referrers(variable_id)
	assert_int(referrers.size()).is_equal(1)

	_remove_item(VARIABLES, variable_id)

	# The condition keeps the id it was pointing at, and the loss is reported.
	var condition: Dictionary = option.get_property_value("condition")
	assert_str(str(condition.get("variable"))).is_equal(variable_id)
	assert_array(_project.get_object_registry().find_dangling()).is_not_empty()
