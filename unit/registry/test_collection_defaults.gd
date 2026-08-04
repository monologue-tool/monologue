extends GdUnitTestSuite

## Some collections nominate one item as the one everything falls back to when a
## reference to them is left empty. The flag lives on the item, so a collection cannot
## claim a fallback its items have nowhere to record.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func test_a_collection_supports_a_default_when_its_items_declare_the_flag() -> void:
	assert_bool(_registry.get_collection("beziers").has_default_item()).is_true()
	assert_bool(_registry.get_collection("portraits").has_default_item()).is_true()


func test_a_collection_whose_items_do_not_declare_it_has_no_default() -> void:
	assert_bool(_registry.get_collection("characters").has_default_item()).is_false()
	assert_bool(_registry.get_collection("variables").has_default_item()).is_false()


func test_a_fresh_item_is_not_the_default() -> void:
	var curve: CollectionItem = _registry.create_collection_item("beziers", _history)

	assert_bool(curve.is_default_item()).is_false()


func test_a_new_project_names_one_default_curve() -> void:
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready

	var defaults: Array = project.get_collection_value("beziers").filter(
		func(record: Dictionary) -> bool: return record.get("is_default") == true
	)

	assert_int(defaults.size()).is_equal(1)
	assert_str(str(defaults[0].get("name"))).is_equal("Ease")


func test_the_resolver_finds_the_default_of_a_collection() -> void:
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready

	assert_str(ReferenceResolver.describe_default(project, "beziers")).is_equal("Ease")


func test_a_collection_without_a_default_resolves_to_nothing() -> void:
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready

	assert_str(ReferenceResolver.find_default(project, "variables")).is_empty()


func test_a_reference_to_a_collection_whose_default_is_gone_resolves_to_nothing() -> void:
	# The dropdown falls back to "<none>" rather than pointing at an item that is no
	# longer there.
	var project: MonologueProject = auto_free(MonologueProject.new())
	await project.ready

	var curves: Array = project.get_collection_value("beziers")
	for record: Dictionary in curves:
		record["is_default"] = false
	project.get_collection("beziers").get_property("beziers").set_value(curves)

	assert_str(ReferenceResolver.find_default(project, "beziers")).is_empty()
	assert_str(ReferenceResolver.describe_default(project, "beziers")).is_empty()


func test_a_character_starts_with_one_default_portrait() -> void:
	var character: CollectionItem = _registry.create_collection_item("characters", _history)

	var defaults: Array = (character.get_property_value("portraits") as Array).filter(
		func(record: Dictionary) -> bool: return record.get("is_default") == true
	)

	assert_int(defaults.size()).is_equal(1)
