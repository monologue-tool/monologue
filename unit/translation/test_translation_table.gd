# gdlint: disable=max-public-methods
extends GdUnitTestSuite

## The translation table is the one place that has to see every translatable line in a
## project, including the ones buried inside a choice node's options. What it cannot
## see cannot be translated.

var _project: MonologueProject


func before_test() -> void:
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project


func after_test() -> void:
	ProjectManager.current_project = null


func _table() -> TranslationTable:
	return TranslationTable.collect(_project)


func _first_node(node_type: String) -> InspectableNode:
	for node: InspectableNode in _project.storylines[0].nodes:
		if node.get_type() == node_type:
			return node
	return null


func _add_language(code: String) -> void:
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"languages", _project.command_manager
	)
	item.set_property_value("name", code)
	item.set_property_value("code", code)

	var collection: CollectionDocument = _project.get_collection("languages")
	var items: Array = collection.get_value().duplicate(true)
	items.append(item._to_dict())
	collection.set_property_value("languages", items)


# --- what it finds ----------------------------------------------------------------


func test_a_sentence_line_is_translatable() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("line", {"en": "Hello"})

	var entry: TranslationEntry = _table().get_entry("%s/line" % sentence.get_id())

	assert_object(entry).is_not_null()
	assert_str(entry.get_text("en")).is_equal("Hello")


func test_plain_text_is_left_alone() -> void:
	# Ids and labels are never read by a player, so they have no business here.
	var sentence: InspectableNode = _first_node("sentence")

	assert_object(_table().get_entry("%s/id" % sentence.get_id())).is_null()
	assert_object(_table().get_entry("%s/label" % sentence.get_id())).is_null()


func test_notes_are_authoring_text_and_are_not_collected() -> void:
	assert_object(
		_table().get_entry("%s/notes" % _first_node("sentence").get_id())
	).is_null()


func test_text_inside_a_choices_option_is_found() -> void:
	# The hard case: it lives in a dictionary inside a property, not on an object.
	var choice: InspectableNode = _first_node("choice")
	var options: Array = choice.get_property_value("choices")
	assert_array(options).is_not_empty()

	var option_id: String = str((options[0] as Dictionary).get("id", ""))
	assert_object(_table().get_entry("%s/text" % option_id)).is_not_null()


# --- writing back -----------------------------------------------------------------


func test_editing_a_line_reaches_the_node() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	var table: TranslationTable = _table()

	assert_bool(table.apply("%s/line" % sentence.get_id(), "fr", "Bonjour")).is_true()

	assert_str(str((sentence.get_property_value("line") as Dictionary).get("fr"))).is_equal(
		"Bonjour"
	)


func test_editing_an_option_reaches_it_through_its_collection() -> void:
	var choice: InspectableNode = _first_node("choice")
	var option_id: String = str(
		((choice.get_property_value("choices") as Array)[0] as Dictionary).get("id", "")
	)
	var table: TranslationTable = _table()

	assert_bool(table.apply("%s/text" % option_id, "fr", "Suivre le chat")).is_true()

	var stored: Dictionary = (choice.get_property_value("choices") as Array)[0]
	assert_str(str((stored["text"] as Dictionary).get("fr"))).is_equal("Suivre le chat")


func test_an_edit_can_be_undone() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	var table: TranslationTable = _table()
	table.apply("%s/line" % sentence.get_id(), "en", "Hello")

	_project.command_manager.undo()

	assert_bool((sentence.get_property_value("line") as Dictionary).has("en")).is_false()


func test_writing_the_same_text_changes_nothing() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	var table: TranslationTable = _table()
	table.apply("%s/line" % sentence.get_id(), "en", "Hello")

	assert_bool(table.apply("%s/line" % sentence.get_id(), "en", "Hello")).is_false()


# --- coverage ---------------------------------------------------------------------


func test_coverage_counts_the_lines_that_read_in_a_language() -> void:
	var table: TranslationTable = _table()
	assert_float(table.coverage("fr")).is_equal(0.0)

	for entry: TranslationEntry in table.entries:
		table.apply(entry.key, "fr", "traduit")

	assert_float(_table().coverage("fr")).is_equal(1.0)


func test_whitespace_does_not_count_as_translated() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	var table: TranslationTable = _table()
	table.apply("%s/line" % sentence.get_id(), "fr", "   ")

	assert_array(table.missing("fr")).contains([table.get_entry("%s/line" % sentence.get_id())])


func test_the_languages_come_from_the_project() -> void:
	_add_language("fr")

	assert_array(TranslationTable.languages_of(_project)).contains(["en", "fr"])
