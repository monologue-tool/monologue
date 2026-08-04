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
	# "text" is both a field type and a node type. A flat name-keyed registry would
	# have silently dropped one of them.
	var text_field: FieldIndexer = _registry.get_field("text")
	var text_node: NodeIndexer = _registry.get_node("text")

	assert_object(text_field).is_not_null()
	assert_object(text_node).is_not_null()
	assert_object(text_field).is_not_same(text_node)
	assert_str(String(text_field.get_object_type())).is_equal(String(MonologueObjectType.FIELD))
	assert_str(String(text_node.get_object_type())).is_equal(String(MonologueObjectType.NODE))


func test_option_exists_as_both_a_field_and_a_node() -> void:
	assert_object(_registry.get_field("option")).is_not_null()
	assert_object(_registry.get_node("option")).is_not_null()
	assert_object(_registry.get_field("option")).is_not_same(_registry.get_node("option"))


func test_the_options_collection_no_longer_collides() -> void:
	# Renamed from "option" so it stops sharing a name with the field and node types.
	assert_object(_registry.get_collection("options")).is_not_null()
	assert_object(_registry.get_collection("option")).is_null()


func test_field_type_ids_are_unique_and_one_based() -> void:
	# 0 is reserved: GraphNode treats slot type 0 as its own default.
	var seen: Array[int] = []
	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.FIELD):
		var type_id: int = (indexer as FieldIndexer).type_id
		assert_int(type_id).is_greater(0)
		assert_bool(type_id in seen).is_false()
		seen.append(type_id)


func test_unknown_names_return_null_rather_than_raising() -> void:
	assert_object(_registry.get_field("no_such_field")).is_null()
	assert_object(_registry.get_node("no_such_node")).is_null()
	assert_object(_registry.get_collection("no_such_collection")).is_null()
	assert_int(_registry.get_field_type_id("no_such_field")).is_equal(0)


func test_text_and_textarea_are_connection_compatible() -> void:
	# compatible_types was dead configuration before: nothing ever taught GraphEdit
	# about these pairs, so a text output could never reach a textarea input.
	var text_id: int = _registry.get_field_type_id("text")
	var textarea_id: int = _registry.get_field_type_id("textarea")

	assert_bool(_registry.is_compatible(text_id, textarea_id)).is_true()
	assert_bool(_registry.is_compatible(textarea_id, text_id)).is_true()


func test_numeric_types_are_mutually_compatible() -> void:
	var int_id: int = _registry.get_field_type_id("int")
	var float_id: int = _registry.get_field_type_id("float")

	assert_bool(_registry.is_compatible(int_id, float_id)).is_true()
	assert_bool(_registry.is_compatible(float_id, int_id)).is_true()


func test_there_is_no_separate_slider_type() -> void:
	# int and float are both drag-and-type now, so a third numeric type would only be a
	# second way to say the same thing.
	assert_object(_registry.get_field("slider")).is_null()


func test_the_any_wildcard_accepts_every_field_type() -> void:
	var any_id: int = _registry.get_field_type_id("any")
	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.FIELD):
		assert_bool(_registry.is_compatible(any_id, (indexer as FieldIndexer).type_id)).is_true()


func test_unrelated_types_are_not_compatible() -> void:
	var bool_id: int = _registry.get_field_type_id("bool")
	var text_id: int = _registry.get_field_type_id("text")
	assert_bool(_registry.is_compatible(bool_id, text_id)).is_false()


func test_registering_a_duplicate_name_is_rejected() -> void:
	var duplicated_indexer: MonologueIndexer = load("res://common/fields/text/index.gd").new()
	assert_bool(_registry.register(duplicated_indexer)).is_false()


func test_indexers_are_tagged_with_the_plugin_that_registered_them() -> void:
	assert_str(_registry.get_field("text").source_plugin).is_equal(MonologueCorePlugin.PLUGIN_NAME)
