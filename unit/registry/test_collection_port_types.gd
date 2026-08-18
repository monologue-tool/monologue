extends GdUnitTestSuite

## A collection's declared port_type has to keep matching its item's actual main property,
## or graph links silently stop working.
##
## An empty port_type is the right answer for a collection whose item has no main property:
## a character list is not a wiring target. That an option node actually reaches a choice's
## list is checked where it is exercised, in unit/runtime/test_story_graph.gd.

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
			"Collection '%s' declares port_type '%s' but its item's main property is '%s'."
			% [collection.name, collection.port_type, expected]
		).is_equal(expected)
