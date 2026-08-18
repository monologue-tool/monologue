extends GdUnitTestSuite

## References point at ids, never at names. These are the guarantees that buys: renaming a
## target keeps every reference, and deleting one breaks them visibly rather than pointing
## them somewhere else.

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


func _set_item_value(collection: String, item_id: String, key: String, value: Variant) -> void:
	var document: CollectionDocument = _project.get_collection(collection)
	var items: Array = document.get_value().duplicate(true)
	for item: Dictionary in items:
		if _read_id(item) == item_id:
			item[key] = value
	document.set_property_value(collection, items)


func _remove_item(collection_name: String, item_id: String) -> void:
	var collection: CollectionDocument = _project.get_collection(collection_name)
	var kept: Array = []
	for item: Dictionary in collection.get_value().duplicate(true):
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
	return str(item.get("id", ""))


func test_renaming_a_target_keeps_every_reference_pointing_at_it() -> void:
	var alice: String = _add_item(CHARACTERS, {"name": "Alice"})
	var twin: String = _add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", alice)

	_set_item_value(CHARACTERS, alice, "name", "Alicia")

	assert_str(str(sentence.get_property_value("speaker"))).is_equal(alice)
	assert_str(
		ReferenceResolver.resolve_label(_project, CHARACTERS, alice, sentence)
	).is_equal("Alicia")

	# Two characters sharing a name were never the same character.
	assert_str(twin).is_not_equal(alice)
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, twin)).is_true()


func test_deleting_a_target_is_reported_and_undoing_repairs_it() -> void:
	var alice: String = _add_item(CHARACTERS, {"name": "Alice"})
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("speaker", alice)

	var referrers: Array[ReferenceSite] = _project.get_object_registry().get_referrers(alice)
	assert_int(referrers.size()).is_equal(1)
	assert_str(referrers[0].owner_id).is_equal(sentence.get_id())
	assert_str(referrers[0].property_name).is_equal("speaker")

	_remove_item(CHARACTERS, alice)

	# The value is kept exactly as it was, so restoring the target repairs it.
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, alice)).is_false()
	assert_str(str(sentence.get_property_value("speaker"))).is_equal(alice)
	assert_array(_issue_codes()).contains([&"dangling_reference"])

	_project.command_manager.undo()

	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, alice)).is_true()
	assert_str(str(sentence.get_property_value("speaker"))).is_equal(alice)


func test_an_id_nothing_carries_resolves_to_nothing_rather_than_to_a_neighbour() -> void:
	_add_item(CHARACTERS, {"name": "Alice"})

	assert_str(
		ReferenceResolver.resolve_label(_project, CHARACTERS, "character-NOTHERE1")
	).is_empty()
	assert_bool(ReferenceResolver.exists(_project, CHARACTERS, "character-NOTHERE1")).is_false()

	# A condition losing its variable keeps the id and is reported, rather than quietly
	# comparing against nothing.
	var trust: String = _add_item(VARIABLES, {"name": "trust", "type": "int"})
	var option: InspectableNode = _first_node("option")
	option.set_property_value("enable_condition", true)
	option.set_property_value("condition", {"variable": trust, "operator": ">=", "value": 3})

	_remove_item(VARIABLES, trust)

	var condition: Dictionary = option.get_property_value("condition")
	assert_str(str(condition.get("variable"))).is_equal(trust)
	assert_array(_project.get_object_registry().find_dangling()).is_not_empty()


func test_undoing_a_node_delete_restores_the_wires_that_pointed_at_it() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var sentence: InspectableNode = _first_node("sentence")
	var initial: Array[Dictionary] = sentence.get_main_property().connected_from.duplicate(true)
	assert_array(initial).is_not_empty()

	_project.command_manager.execute(
		DeleteNodesCommand.new(storyline.id, [_first_node("root")])
	)
	assert_array(sentence.get_main_property().connected_from).is_empty()

	_project.command_manager.undo()

	assert_array(sentence.get_main_property().connected_from).is_equal(initial)


func test_an_id_is_allocated_once_and_reads_as_what_it_names() -> void:
	var generated: String = IDGen.generate_object_id("sentence")
	var suffix: String = generated.trim_prefix("sentence-")
	assert_str(generated).starts_with("sentence-")
	assert_int(suffix.length()).is_equal(IDGen.DEFAULT_LENGTH)
	for character: String in suffix:
		assert_bool(IDGen.ALPHABET.contains(character)).override_failure_message(
			"'%s' is not a Crockford base32 character." % character
		).is_true()

	# A collision is caught rather than left for two objects to share.
	var registry: ProjectObjectRegistry = ProjectObjectRegistry.new()
	assert_str(registry.allocate_id("character", "character-DUPLICAT")).is_equal(
		"character-DUPLICAT"
	)
	assert_str(registry.allocate_id("character", "character-DUPLICAT")).is_not_equal(
		"character-DUPLICAT"
	)

	# Registering an object whose id is taken rewrites the newcomer, so both stay reachable.
	var first: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		CHARACTERS, _project.command_manager
	)
	var twin: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		CHARACTERS, _project.command_manager
	)
	twin.get_property("id").value = first.get_property_value("id")
	var fresh: ProjectObjectRegistry = ProjectObjectRegistry.new()
	fresh.register(first)
	fresh.register(twin)

	assert_str(str(twin.get_property_value("id"))).is_not_equal(
		str(first.get_property_value("id"))
	)
	assert_object(fresh.get_object(str(twin.get_property_value("id")))).is_same(twin)

	# A new item is born with a name of its own, and one a condition can actually spell.
	var variable: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		VARIABLES, _project.command_manager
	)
	var sibling: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		VARIABLES, _project.command_manager
	)
	assert_str(str(variable.get_property_value("name"))).is_not_equal(
		str(sibling.get_property_value("name"))
	)
	assert_bool(str(variable.get_property_value("name")).is_valid_identifier()).is_true()


func test_a_reference_port_is_typed_and_labelled_by_what_it_accepts() -> void:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	var characters: int = registry.get_reference_type_id(CHARACTERS)
	var eases: int = registry.get_reference_type_id("eases")

	assert_int(characters).is_greater(0)
	# Asking twice gives the same port, or a link would stop matching on redraw.
	assert_int(registry.get_reference_type_id(CHARACTERS)).is_equal(characters)
	assert_bool(registry.is_compatible(characters, eases)).override_failure_message(
		"A character reference must not accept an ease reference."
	).is_false()

	# Nor may a reference port collide with a field port: they share one id space.
	for indexer: MonologueIndexer in registry.list(MonologueObjectType.FIELD):
		assert_int((indexer as FieldIndexer).type_id).is_not_equal(characters)

	# "reference" says nothing: every reference port would read the same.
	var character: CollectionItem = registry.create_collection_item(
		CHARACTERS, _project.command_manager
	)
	assert_str(ReferenceResolver.describe_scope(CHARACTERS)).is_equal("character")
	assert_str(ReferenceResolver.describe_scope("node:option")).is_equal("option")
	assert_str(ReferenceResolver.describe_scope("self:portraits", character)).is_equal("portrait")
	assert_str(ReferenceResolver.describe_scope("")).is_empty()
	assert_str(ReferenceResolver.describe_scope("nothing_registered_here")).is_empty()

	# Guessing an item type by trimming an "s" is what broke every option link when the
	# collection was renamed; it is read off the item instead, for all of them at once.
	for indexer: MonologueIndexer in registry.list(MonologueObjectType.COLLECTION):
		var collection: CollectionIndexer = indexer
		var item: CollectionItem = collection.instantiate(_project.command_manager)
		assert_str(collection.get_item_type()).override_failure_message(
			"Collection '%s' reports item type '%s' but its items say '%s'."
			% [collection.name, collection.get_item_type(), item.get_type()]
		).is_equal(item.get_type())


func test_nothing_a_person_reads_is_an_id() -> void:
	assert_str(Util.to_label({"en": "Hello"}, "en")).is_equal("Hello")
	# No English yet, but the item is not nameless: show what there is.
	assert_str(Util.to_label({"fr": "Bonjour"}, "en")).is_equal("Bonjour")
	assert_str(Util.to_label({"en": "   "}, "en")).is_empty()
	assert_str(Util.to_label("plain")).is_equal("plain")
	assert_str(Util.to_label(null)).is_empty()

	var choice: InspectableNode = _first_node("choice")
	var nameless: Array[Dictionary] = ReferenceResolver.list_candidates(
		_project, "self:choices", choice
	)
	assert_array(nameless).is_not_empty()
	for candidate: Dictionary in nameless:
		var label: String = str(candidate["label"])
		assert_str(label).is_not_equal(str(candidate["id"]))
		assert_bool(label.begins_with("Option ")).override_failure_message(
			"A nameless option is labelled '%s'." % label
		).is_true()

	var options: Array = (choice.get_property_value("choices") as Array).duplicate(true)
	options[0]["text"] = {"en": "Follow the cat"}
	choice.set_property_value("choices", options)

	assert_str(
		str(ReferenceResolver.list_candidates(_project, "self:choices", choice)[0]["label"])
	).is_equal("Follow the cat")
