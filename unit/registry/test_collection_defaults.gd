extends GdUnitTestSuite

## Some collections nominate one item as the one everything falls back to when a reference
## to them is left empty. The flag lives on the item, so a collection cannot claim a
## fallback its items have nowhere to record.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_a_collection_claims_a_default_exactly_when_its_items_can_hold_one() -> void:
	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.COLLECTION):
		var collection: CollectionIndexer = indexer
		var item: CollectionItem = collection.instantiate(_history)

		assert_bool(collection.has_default_item()).override_failure_message(
			"Collection '%s' claims a default its item cannot record, or the reverse."
			% collection.name
		).is_equal(item.get_property("is_default") != null)

		if collection.has_default_item():
			assert_bool(item.is_default_item()).override_failure_message(
				"A fresh '%s' item is born as the default." % collection.name
			).is_false()

		_assert_nested_defaults(item, collection.name)


## An item owning a sub-collection that supports a default is born with exactly one, so a
## fresh character already has a portrait to fall back on. Walked rather than named: the
## project-level pass cannot see a collection that only exists inside an item.
func _assert_nested_defaults(item: CollectionItem, owner_name: String) -> void:
	for property: Property in item.get_properties():
		if property.type != "collection":
			continue
		var nested_name: String = str(
			property.get_settings_value(PropertySettings.KEY_COLLECTION, "")
		)
		var nested: CollectionIndexer = _registry.get_collection(nested_name)
		if nested == null or not nested.has_default_item():
			continue

		var defaults: Array = _defaults_in(property.get_value())
		assert_int(defaults.size()).override_failure_message(
			"A fresh '%s' holds %d default '%s'." % [owner_name, defaults.size(), nested_name]
		).is_equal(1)


func test_a_new_project_names_one_default_where_one_is_supported() -> void:
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready

	var supported: int = 0
	for document: CollectionDocument in project.collections:
		var collection: CollectionIndexer = _registry.get_collection(document.name)
		if collection == null or not collection.has_default_item():
			continue
		supported += 1

		var defaults: Array = _defaults_in(project.get_collection_value(document.name))
		assert_int(defaults.size()).override_failure_message(
			"'%s' supports a default but a new project names %d." % [document.name, defaults.size()]
		).is_equal(1)
		assert_str(ReferenceResolver.find_default(project, document.name)).is_not_empty()
		assert_str(ReferenceResolver.describe_default(project, document.name)).is_equal(
			str(defaults[0].get("name"))
		)

	assert_int(supported).override_failure_message(
		"No project-level collection supports a default, so this proves nothing."
	).is_greater(0)


func test_a_reference_to_a_default_that_is_gone_resolves_to_nothing() -> void:
	# The dropdown falls back to "<none>" rather than pointing at an item that has left.
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready

	var records: Array = project.get_collection_value("eases")
	for record: Dictionary in records:
		record["is_default"] = false
	project.get_collection("eases").get_property("eases").set_value(records)

	assert_str(ReferenceResolver.find_default(project, "eases")).is_empty()
	assert_str(ReferenceResolver.describe_default(project, "eases")).is_empty()


static func _defaults_in(records: Array) -> Array:
	return records.filter(func(record: Dictionary) -> bool: return record.get("is_default") == true)
