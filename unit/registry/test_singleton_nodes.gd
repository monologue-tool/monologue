extends GdUnitTestSuite

## Some node types may exist once per storyline and no more. The root is the one: it is not
## offered by the add menus and cannot be deleted, so a storyline has exactly one way in.
##
## Which is two separate guarantees. The document only reports the count; it is the project's
## template that puts the root there in the first place.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func _singleton_issues(storyline: StorylineDocument) -> Array[ValidationIssue]:
	var result: ValidationResult = ValidationResult.ok()
	storyline.validate_object(result, null)
	return result.with_code(&"singleton_count")


func test_a_storyline_reports_any_count_of_a_singleton_but_one() -> void:
	# A document builds nothing of its own, so this starts with none -- which is as wrong as
	# having two, and is what "no way in" looks like.
	var storyline: StorylineDocument = StorylineDocument.new("main", _history)
	assert_array(_singleton_issues(storyline)).override_failure_message(
		"A storyline with no root at all went unreported."
	).is_not_empty()

	storyline.create_node("root")
	assert_array(_singleton_issues(storyline)).override_failure_message(
		"A storyline with exactly one root was reported anyway."
	).is_empty()

	storyline.create_node("root")
	assert_array(_singleton_issues(storyline)).override_failure_message(
		"A second root went unreported."
	).is_not_empty()


func test_a_storyline_the_editor_makes_comes_with_one_of_each_singleton() -> void:
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready
	var storyline: StorylineDocument = project.storylines[0]
	var singletons: int = 0

	for indexer: MonologueIndexer in _registry.list(MonologueObjectType.NODE):
		if not (indexer as NodeIndexer).is_singleton:
			continue

		var node_type: String = indexer.name
		var born: Array = storyline.nodes.filter(
			func(node: InspectableNode) -> bool: return node.get_type() == node_type
		)
		singletons += 1

		assert_int(born.size()).override_failure_message(
			"'%s' is a singleton but a new storyline holds %d." % [node_type, born.size()]
		).is_equal(1)
		assert_bool(NodeIndexer.is_permanent(born[0])).override_failure_message(
			"'%s' is a singleton the user could still delete." % node_type
		).is_true()

	assert_int(singletons).override_failure_message(
		"No node type is a singleton, so this proves nothing."
	).is_greater(0)
