extends GdUnitTestSuite

## The translation table is the one place that has to see every translatable line in a
## project, including the ones buried inside a choice node's options. What it cannot see
## cannot be translated.

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


func _first_option_id() -> String:
	var options: Array = _first_node("choice").get_property_value("choices")
	return str((options[0] as Dictionary).get("id", ""))


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


func test_it_finds_what_a_player_reads_and_nothing_else() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	sentence.set_property_value("line", {"en": "Hello"})
	var table: TranslationTable = _table()

	var line: TranslationEntry = table.get_entry("%s/line" % sentence.get_id())
	assert_object(line).is_not_null()
	assert_str(line.get_text("en")).is_equal("Hello")

	# The hard case: an option's text lives in a dictionary inside a property, not on an
	# object of its own.
	assert_object(table.get_entry("%s/text" % _first_option_id())).is_not_null()

	# Ids, labels and authoring notes are never read by a player.
	for untranslatable: String in ["id", "label", "notes"]:
		assert_object(
			table.get_entry("%s/%s" % [sentence.get_id(), untranslatable])
		).override_failure_message(
			"'%s' is authoring text and has no business being translated." % untranslatable
		).is_null()


func test_coverage_counts_a_line_only_once_it_actually_reads() -> void:
	_add_language("fr")
	assert_array(TranslationTable.languages_of(_project)).override_failure_message(
		"A language the project declares is not one the table knows to count."
	).contains(["en", "fr"])

	var table: TranslationTable = _table()
	assert_float(table.coverage("fr")).is_equal(0.0)

	var sentence: InspectableNode = _first_node("sentence")
	table.apply("%s/line" % sentence.get_id(), "fr", "   ")
	assert_array(table.missing("fr")).override_failure_message(
		"Whitespace counted as a translation."
	).contains([table.get_entry("%s/line" % sentence.get_id())])

	for entry: TranslationEntry in table.entries:
		table.apply(entry.key, "fr", "traduit")

	assert_float(_table().coverage("fr")).is_equal(1.0)


func test_an_entry_carries_what_an_editor_needs_to_draw_it() -> void:
	var sentence: InspectableNode = _first_node("sentence")
	var narrator: String = str(
		(_project.get_collection_value("characters")[0] as Dictionary).get("id", "")
	)
	sentence.set_property_value("speaker", narrator)

	var entry: TranslationEntry = _table().get_entry("%s/line" % sentence.get_id())

	assert_str(entry.object_type).is_equal("sentence")
	assert_str(entry.property_name).is_equal("line")
	assert_str(entry.speaker).is_equal("Narrator")
	# A sentence line is declared multiline; an editor that ignored that would swallow every
	# line break the translator typed.
	assert_bool(entry.is_multiline()).is_true()
	assert_int(entry.get_rows()).is_greater(0)
