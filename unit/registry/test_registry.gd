extends GdUnitTestSuite

## Registry behaviour that the old three-Bucket design could not express.
## Runs headless: MonologueRegistry never touches the SceneTree.

var _registry: MonologueRegistry


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_a_name_may_be_reused_across_object_types() -> void:
	# "text" and "option" are each both a field type and a node type. A flat name-keyed
	# registry would have silently dropped one of the two.
	for shared_name: String in ["text", "option"]:
		var field: FieldIndexer = _registry.get_field(shared_name)
		var node: NodeIndexer = _registry.get_node(shared_name)

		assert_object(field).is_not_null()
		assert_object(node).is_not_null()
		assert_object(field).is_not_same(node)
		assert_str(String(field.get_object_type())).is_equal(String(MonologueObjectType.FIELD))
		assert_str(String(node.get_object_type())).is_equal(String(MonologueObjectType.NODE))


func test_every_field_type_has_a_usable_id_and_the_wildcard_reaches_it() -> void:
	# 0 is reserved: GraphEdit treats slot type 0 as its own default.
	var seen: Array[int] = []
	var any_id: int = _registry.get_field_type_id("any")

	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.FIELD):
		var type_id: int = (indexer as FieldIndexer).type_id
		assert_int(type_id).override_failure_message(
			"Field '%s' has id 0, which GraphEdit reads as no type." % indexer.name
		).is_greater(0)
		assert_bool(type_id in seen).override_failure_message(
			"Field '%s' reuses id %d." % [indexer.name, type_id]
		).is_false()
		seen.append(type_id)

		assert_bool(_registry.is_compatible(any_id, type_id)).override_failure_message(
			"The 'any' wildcard does not accept '%s'." % indexer.name
		).is_true()


func test_compatibility_is_declared_both_ways_and_is_not_universal() -> void:
	# compatible_types was dead configuration before: nothing ever taught GraphEdit about
	# these pairs, so a text output could never reach a textarea input.
	for pair: Array in [["text", "textarea"], ["int", "float"]]:
		var left: int = _registry.get_field_type_id(pair[0])
		var right: int = _registry.get_field_type_id(pair[1])
		assert_bool(_registry.is_compatible(left, right)).is_true()
		assert_bool(_registry.is_compatible(right, left)).is_true()

	assert_bool(
		_registry.is_compatible(
			_registry.get_field_type_id("bool"), _registry.get_field_type_id("text")
		)
	).override_failure_message("Everything became compatible with everything.").is_false()


func test_the_registry_refuses_a_duplicate_and_answers_null_for_a_stranger() -> void:
	var already_registered: MonologueIndexer = load("res://common/fields/text/index.gd").new()
	assert_bool(_registry.register(already_registered)).is_false()

	assert_object(_registry.get_field("no_such_field")).is_null()
	assert_object(_registry.get_node("no_such_node")).is_null()
	assert_object(_registry.get_collection("no_such_collection")).is_null()
	assert_int(_registry.get_field_type_id("no_such_field")).is_equal(0)
