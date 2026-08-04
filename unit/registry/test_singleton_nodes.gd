extends GdUnitTestSuite

## A storyline owns its root rather than the user: it is not offered by the add menus
## and cannot be deleted, so a storyline always has exactly one way in.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_the_root_is_declared_as_a_singleton() -> void:
	assert_bool(_registry.get_node("root").is_singleton).is_true()


func test_no_other_node_type_is_a_singleton() -> void:
	var singletons: PackedStringArray = []
	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.NODE):
		if (indexer as NodeIndexer).is_singleton:
			singletons.append(indexer.name)

	assert_array(singletons).contains_exactly(["root"])


func test_a_root_node_reports_itself_as_permanent() -> void:
	assert_bool(NodeIndexer.is_permanent(_registry.create_node("root", _history))).is_true()
	assert_bool(NodeIndexer.is_permanent(_registry.create_node("sentence", _history))).is_false()


func test_a_new_storyline_comes_with_exactly_one_root() -> void:
	var storyline: StorylineDocument = StorylineDocument.new("main", _history)

	var roots: Array = storyline.nodes.filter(
		func(node: InspectableNode) -> bool: return node.get_type() == "root"
	)

	assert_int(roots.size()).is_equal(1)


func test_a_storyline_with_two_roots_is_reported() -> void:
	var storyline: StorylineDocument = StorylineDocument.new("main", _history)
	storyline.create_node("root")

	var result: ValidationResult = ValidationResult.ok()
	storyline.validate_object(result, null)

	assert_array(result.with_code(&"singleton_count")).is_not_empty()


func test_a_storyline_with_its_one_root_is_reported_clean() -> void:
	var storyline: StorylineDocument = StorylineDocument.new("main", _history)

	var result: ValidationResult = ValidationResult.ok()
	storyline.validate_object(result, null)

	assert_array(result.with_code(&"singleton_count")).is_empty()
