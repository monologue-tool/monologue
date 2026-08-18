extends GdUnitTestSuite

## Every node type is declared in two places: an index.gd that registers it and a script
## that says what it holds. These check the two still agree, for all of them at once, so a
## new node type is covered the moment it is added to the plugin.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func _each_node() -> Array[NodeIndexer]:
	var indexers: Array[NodeIndexer] = []
	indexers.assign(_registry.list(MonologueObjectType.NODE))
	return indexers


func test_a_node_is_registered_once_under_the_name_it_reports() -> void:
	# Otherwise create_node("wait") returns something calling itself something else, and the
	# mismatch only shows up when a saved file cannot be read back.
	var seen: Dictionary[String, bool] = {}

	for indexer: NodeIndexer in _each_node():
		assert_bool(seen.has(indexer.name)).override_failure_message(
			"Two node types are registered as '%s'." % indexer.name
		).is_false()
		seen[indexer.name] = true

		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		assert_str(node.get_type()).override_failure_message(
			"Node registered as '%s' reports its type as '%s'." % [indexer.name, node.get_type()]
		).is_equal(indexer.name)


func test_every_node_declares_exactly_one_main_property() -> void:
	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		var main_properties: Array[Property] = []
		for property: Property in node.get_properties():
			if property.is_main_property():
				main_properties.append(property)

		# Zero usually means the name collided: InspectableNode declares id, color, label,
		# notes and editor_position on every node, and the ones it adds after
		# initialize_properties() overwrite a main property of the same name.
		assert_int(main_properties.size()).override_failure_message(
			"Node '%s' declares %d main properties." % [indexer.name, main_properties.size()]
		).is_equal(1)


func test_every_property_a_node_declares_points_at_something_real() -> void:
	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		for property: Property in node.get_properties():
			assert_object(_registry.get_field(property.type)).override_failure_message(
				"Node '%s' declares '%s' as type '%s', which is not registered."
				% [indexer.name, property.name, property.type]
			).is_not_null()

			if property.type != "reference":
				continue
			var scope: String = str(
				property.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, "")
			)
			assert_str(ReferenceResolver.describe_scope(scope, node)).override_failure_message(
				"Node '%s' points '%s' at scope '%s', which resolves to nothing."
				% [indexer.name, property.name, scope]
			).is_not_empty()


func test_no_node_ever_previews_an_id() -> void:
	# The preview exists so a graph reads at a glance, and an id says nothing to whoever is
	# reading it. A reference pointing at nothing has to read as nothing, not as its target.
	var shaped_like_an_id: RegEx = RegEx.create_from_string("[a-z_]+-[A-Z0-9]{6,}")

	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		var shown: String = _words_in(node._build_preview("en"))

		assert_object(shaped_like_an_id.search(shown)).override_failure_message(
			"Empty '%s' previews '%s', which carries an id." % [indexer.name, shown]
		).is_null()


func test_no_preview_decides_how_big_its_node_is() -> void:
	# A preview is drawn in whatever room the ports above it already claimed. It may ask for
	# height, up to a bound; it may never ask for width, or one long line would widen the
	# node and every node would end up as wide as its wordiest neighbour.
	var project: MonologueProject = await _opened_project()
	var speaker: String = _first_record_id(project, "characters")
	var variable: String = _long_variable(project)
	var previewed: int = 0

	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		for property: Property in node.get_properties():
			property.set_value(_something_long(property, speaker, variable))

		var preview: Control = node._build_preview("en")
		if preview == null:
			continue
		previewed += 1
		auto_free(preview)

		assert_float(preview.custom_minimum_size.x).override_failure_message(
			"'%s' asks for %d pixels of width." % [indexer.name, preview.custom_minimum_size.x]
		).is_equal(0.0)
		assert_float(preview.custom_minimum_size.y).override_failure_message(
			"'%s' asks to be %d pixels tall." % [indexer.name, preview.custom_minimum_size.y]
		).is_less_equal(GraphNodeViewFactory.PREVIEW_MAX_HEIGHT)

	ProjectManager.current_project = null
	assert_int(previewed).override_failure_message(
		"No node previewed anything, so this proves nothing."
	).is_greater(8)


func test_a_sentence_previews_as_who_says_what() -> void:
	var project: MonologueProject = await _opened_project()
	var narrator: String = str(
		(project.get_collection_value("characters")[0] as Dictionary).get("name", "")
	)

	var node: InspectableNode = _registry.create_node("sentence", _history)
	node.get_property("speaker").set_value(_first_record_id(project, "characters"))
	node.get_property("line").set_value({"en": "Hello there.", "fr": "Bonjour."})

	var english: String = _words_in(node._build_preview("en"))
	assert_str(english).contains(narrator)
	assert_str(english).contains("Hello there.")

	# The reader's language, not whichever one it happened to be written in first.
	assert_str(_words_in(node._build_preview("fr"))).override_failure_message(
		"A preview showed the language it was written in rather than the one being read."
	).contains("Bonjour.")

	ProjectManager.current_project = null


## Everything a preview puts into words, however it chose to arrange it. Frees what it walks:
## a preview built outside the graph belongs to nobody.
func _words_in(preview: Control) -> String:
	if preview == null:
		return ""

	var written: String = _written_in(preview)
	preview.free()
	return written


func _written_in(control: Control) -> String:
	var written: PackedStringArray = []
	if control is RichTextLabel:
		written.append((control as RichTextLabel).text)
	elif control is Label:
		written.append((control as Label).text)

	for child: Node in control.get_children():
		if child is Control:
			written.append(_written_in(child))
	return " ".join(written)


## A project the editor is holding open, which is where a preview reads names from.
func _opened_project() -> MonologueProject:
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready
	ProjectManager.current_project = project
	return project


func _first_record_id(project: MonologueProject, collection_name: String) -> String:
	var records: Array = project.get_collection_value(collection_name)
	return str((records[0] as Dictionary).get("id", "")) if not records.is_empty() else ""


## A variable with a name long enough to push a condition preview as wide as it will go.
func _long_variable(project: MonologueProject) -> String:
	var item: CollectionItem = _registry.create_collection_item(
		"variables", project.command_manager
	)
	item.set_property_value("name", "an_extremely_long_variable_name_indeed")
	item.set_property_value("type", "int")

	var document: CollectionDocument = project.get_collection("variables")
	var records: Array = document.get_value().duplicate(true)
	records.append(item._to_dict())
	document.set_property_value("variables", records)
	return str(item.get_property_value("id"))


## Something oversized of whatever shape [param property] holds, so a preview built out of it
## is pushed as wide as that property can push it.
func _something_long(property: Property, speaker: String, variable: String) -> Variant:
	var long: String = "Bartholomew".repeat(8)
	match property.type:
		"text", "textarea":
			return {"en": long} if property.is_translatable() else long
		"int", "float":
			return 99999
		"bool":
			return true
		"file":
			return "res://a/deeply/nested/folder/%s.png" % long
		"list":
			return [long, long, long]
		"condition":
			return {"variable": variable, "operator": ">=", "value": long}
		"reference":
			var scope: String = str(
				property.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, "")
			)
			return variable if scope == "variables" else speaker
	return property.get_value()

