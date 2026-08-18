extends GdUnitTestSuite

## Guards the explicit preload lists in MonologueCorePlugin. A dropped line there makes a
## whole type silently disappear from the editor, which is otherwise easy to miss.
##
## Counted rather than named: a list of the types that exist today would have to be edited
## every time one is added, and would then only ever confirm its own contents.

var _registry: MonologueRegistry


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_the_core_plugin_registers_all_it_declares_and_takes_it_all_back() -> void:
	var declared: Dictionary = {
		MonologueObjectType.FIELD: MonologueCorePlugin.FIELDS.size(),
		MonologueObjectType.NODE: MonologueCorePlugin.NODES.size(),
		MonologueObjectType.COLLECTION: MonologueCorePlugin.COLLECTIONS.size(),
	}

	for object_type: StringName in declared:
		assert_int(_registry.list(object_type).size()).override_failure_message(
			"%s: %d preloaded, %d registered." % [
				object_type, declared[object_type], _registry.list(object_type).size()
			]
		).is_equal(declared[object_type])

	_registry.uninstall(MonologueCorePlugin.PLUGIN_NAME)

	for object_type: StringName in MonologueObjectType.ALL:
		assert_int(_registry.list(object_type).size()).is_equal(0)
