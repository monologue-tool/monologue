extends GdUnitTestSuite

## The behaviour that the whole "annotate, never block" decision rests on.
##
## Committing an invalid value used to call _sync_from_property(), which put the old
## value back with no message at all: typing an empty name simply made the previous
## name reappear and the user had no idea why.

var _history: CommandManager
var _registry: MonologueRegistry


func before_test() -> void:
	_history = CommandManager.new()
	_registry = MonologueRegistry.get_instance()


func _new_variable() -> CollectionItem:
	return _registry.create_collection_item("variables", _history)


func test_an_invalid_value_is_still_written() -> void:
	var variable: CollectionItem = _new_variable()

	variable.set_property_value("name", "")

	assert_str(variable.get_property_value("name")).is_equal("")


func test_an_invalid_value_is_reported() -> void:
	var variable: CollectionItem = _new_variable()
	variable.set_property_value("name", "")

	var result: ValidationResult = ValidationService.validate_property(
		variable.get_property("name"), variable
	)

	assert_bool(result.is_valid()).is_false()
	assert_array(result.with_code(&"required")).is_not_empty()


func test_the_issues_are_left_on_the_property_for_the_field_to_render() -> void:
	var variable: CollectionItem = _new_variable()
	variable.set_property_value("name", "")

	ValidationService.validate_property(variable.get_property("name"), variable)

	assert_array(variable.get_property("name").issues).is_not_empty()


func test_fixing_the_value_clears_the_issues() -> void:
	var variable: CollectionItem = _new_variable()
	variable.set_property_value("name", "")
	ValidationService.validate_property(variable.get_property("name"), variable)
	assert_array(variable.get_property("name").issues).is_not_empty()

	variable.set_property_value("name", "health")
	ValidationService.validate_property(variable.get_property("name"), variable)

	assert_array(variable.get_property("name").issues).is_empty()


func test_an_invalid_value_still_goes_through_the_undo_history() -> void:
	# Being invalid must not cost the user their undo step either.
	var variable: CollectionItem = _new_variable()

	variable.set_property_value("name", "")

	assert_bool(_history.undo_redo.has_undo()).is_true()


func test_a_name_with_a_space_is_reported_by_the_declared_validator() -> void:
	# VariableCollectionItem declares .validate(_must_be_an_identifier).
	var variable: CollectionItem = _new_variable()
	variable.set_property_value("name", "not an identifier")

	var result: ValidationResult = ValidationService.validate_property(
		variable.get_property("name"), variable
	)

	assert_array(result.with_code(&"variable_name")).is_not_empty()


func test_a_valid_identifier_passes() -> void:
	var variable: CollectionItem = _new_variable()
	variable.set_property_value("name", "player_health")

	var result: ValidationResult = ValidationService.validate_property(
		variable.get_property("name"), variable
	)

	assert_bool(result.is_valid()).is_true()


func test_an_option_with_an_enabled_but_empty_condition_is_only_a_warning() -> void:
	var option: InspectableNode = _registry.create_node("option", _history)
	option.set_property_value("enable_condition", true)

	var result: ValidationResult = ValidationService.validate_object(option)

	assert_array(result.with_code(&"empty_condition")).is_not_empty()
	assert_bool(result.is_valid()).is_true()


func test_an_option_with_no_condition_switch_says_nothing() -> void:
	var option: InspectableNode = _registry.create_node("option", _history)

	var result: ValidationResult = ValidationService.validate_object(option)

	assert_array(result.with_code(&"empty_condition")).is_empty()
