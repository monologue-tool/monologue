extends GdUnitTestSuite

## Guards the explicit preload lists in MonologueCorePlugin. A dropped line there makes
## a whole type silently disappear from the editor, which is otherwise easy to miss.

var _registry: MonologueRegistry


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_every_declared_type_is_registered() -> void:
	assert_int(_registry.list(MonologueObjectType.FIELD).size()).is_equal(
		MonologueCorePlugin.FIELDS.size()
	)
	assert_int(_registry.list(MonologueObjectType.NODE).size()).is_equal(
		MonologueCorePlugin.NODES.size()
	)
	assert_int(_registry.list(MonologueObjectType.COLLECTION).size()).is_equal(
		MonologueCorePlugin.COLLECTIONS.size()
	)


func test_the_expected_types_are_present() -> void:
	for field_name: String in [
		"text", "int", "float", "bool", "collection", "condition", "reference", "translatable"
	]:
		assert_object(_registry.get_field(field_name)).is_not_null()
	for node_name: String in [
		"root",
		"sentence",
		"choice",
		"option",
		"text",
		"audio",
		"background",
		"condition",
		"reroute",
		"storyline",
		"wait",
		"zoo",
	]:
		assert_object(_registry.get_node(node_name)).is_not_null()
	for collection_name: String in ["characters", "variables", "languages", "options"]:
		assert_object(_registry.get_collection(collection_name)).is_not_null()


func test_uninstalling_the_core_plugin_empties_the_registry() -> void:
	_registry.uninstall(MonologueCorePlugin.PLUGIN_NAME)

	for object_type: StringName in MonologueObjectType.ALL:
		assert_int(_registry.list(object_type).size()).is_equal(0)
