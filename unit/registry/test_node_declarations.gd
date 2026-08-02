extends GdUnitTestSuite

## Every node type is declared in two places: an index.gd that registers it and a script
## that says what it holds. These check the two still agree, for all of them at once, so
## a new node type is covered the moment it is added to the plugin.

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


func test_a_node_reports_the_type_it_is_registered_under() -> void:
	# Otherwise create_node("wait") returns something calling itself something else, and
	# the mismatch only shows up when a saved file cannot be read back.
	for indexer: NodeIndexer in _each_node():
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

		assert_int(main_properties.size()).override_failure_message(
			"Node '%s' declares %d main properties." % [indexer.name, main_properties.size()]
		).is_equal(1)


func test_every_property_uses_a_registered_field_type() -> void:
	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		for property: Property in node.get_properties():
			assert_object(_registry.get_field(property.type)).override_failure_message(
				"Node '%s' declares '%s' as type '%s', which is not registered."
				% [indexer.name, property.name, property.type]
			).is_not_null()


func test_every_reference_property_names_a_scope_that_resolves() -> void:
	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode
		for property: Property in node.get_properties():
			if property.type != "reference":
				continue
			var scope: String = str(
				property.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, "")
			)
			assert_str(ReferenceResolver.describe_scope(scope, node)).override_failure_message(
				"Node '%s' points '%s' at scope '%s', which resolves to nothing."
				% [indexer.name, property.name, scope]
			).is_not_empty()


func test_a_node_type_has_unique_name() -> void:
	var seen: Dictionary[String, bool] = {}
	for indexer: NodeIndexer in _each_node():
		assert_bool(seen.has(indexer.name)).override_failure_message(
			"Two node types are registered as '%s'." % indexer.name
		).is_false()
		seen[indexer.name] = true
