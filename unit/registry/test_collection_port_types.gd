extends GdUnitTestSuite

## A collection's declared port_type has to keep matching its item's actual main
## property, or graph links silently stop working.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_declared_port_types_match_the_items_main_property() -> void:
	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.COLLECTION):
		var collection: CollectionIndexer = indexer
		var item: CollectionItem = collection.instantiate(_history)
		var main_property: Property = null
		for property: Property in item.get_properties():
			if property.is_main_property():
				main_property = property
				break

		var expected: String = main_property.type if main_property else ""
		assert_str(collection.port_type).override_failure_message(
			(
				"Collection '%s' declares port_type '%s' but its item's main property is '%s'."
				% [collection.name, collection.port_type, expected]
			)
		).is_equal(expected)


func test_an_option_node_can_be_wired_into_a_choice_option_list() -> void:
	var option_node: InspectableNode = _registry.create_node("option", _history)
	var choice_node: InspectableNode = _registry.create_node("choice", _history)

	var option_output: Property = option_node.get_main_property()
	var choices_input: Property = choice_node.get_property("choices")

	var output_type_id: int = _registry.get_field_type_id(option_output.type)
	var input_type_id: int = _registry.get_field_type_id(
		_registry.get_collection(
			choices_input.get_settings_value(PropertySettings.KEY_COLLECTION, "")
		).port_type
	)

	assert_int(output_type_id).is_greater(0)
	assert_int(input_type_id).is_greater(0)
	assert_bool(_registry.is_compatible(output_type_id, input_type_id)).override_failure_message(
		"An option node can no longer be connected to a choice node's option list."
	).is_true()


func test_a_collection_without_a_port_type_is_not_connectable() -> void:
	# Characters have no main property, so a character list is not a wiring target.
	assert_str(_registry.get_collection("characters").port_type).is_empty()
