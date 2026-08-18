extends GdUnitTestSuite

## The behaviour that the whole "annotate, never block" decision rests on.
##
## Committing an invalid value used to call _sync_from_property(), which put the old value
## back with no message at all: typing an empty name simply made the previous name reappear
## and the user had no idea why.

var _history: CommandManager
var _registry: MonologueRegistry


func before_test() -> void:
	_history = CommandManager.new()
	_registry = MonologueRegistry.get_instance()


func _new_variable() -> CollectionItem:
	return _registry.create_collection_item("variables", _history)


func test_an_invalid_value_is_written_kept_and_reported() -> void:
	var variable: CollectionItem = _new_variable()

	variable.set_property_value("name", "")

	assert_str(variable.get_property_value("name")).is_equal("")
	# Being invalid must not cost the user their undo step either.
	assert_bool(_history.undo_redo.has_undo()).is_true()

	var result: ValidationResult = ValidationService.validate_property(
		variable.get_property("name"), variable
	)

	assert_bool(result.is_valid()).is_false()
	assert_array(result.with_code(&"required")).is_not_empty()
	# Left on the property, which is where the field reads them to draw itself.
	assert_array(variable.get_property("name").issues).is_not_empty()


func test_a_declared_validator_reports_and_then_gets_out_of_the_way() -> void:
	# VariableCollectionItem declares .validate(_must_be_an_identifier).
	var variable: CollectionItem = _new_variable()
	variable.set_property_value("name", "not an identifier")

	var rejected: ValidationResult = ValidationService.validate_property(
		variable.get_property("name"), variable
	)
	assert_array(rejected.with_code(&"variable_name")).is_not_empty()

	variable.set_property_value("name", "player_health")
	var accepted: ValidationResult = ValidationService.validate_property(
		variable.get_property("name"), variable
	)

	assert_bool(accepted.is_valid()).is_true()
	assert_array(variable.get_property("name").issues).is_empty()


func test_a_warning_says_its_piece_without_making_the_object_invalid() -> void:
	var switched_on: InspectableNode = _registry.create_node("option", _history)
	switched_on.set_property_value("enable_condition", true)

	var warned: ValidationResult = ValidationService.validate_object(switched_on)

	assert_array(warned.with_code(&"empty_condition")).is_not_empty()
	assert_bool(warned.is_valid()).is_true()

	var untouched: ValidationResult = ValidationService.validate_object(
		_registry.create_node("option", _history)
	)
	assert_array(untouched.with_code(&"empty_condition")).is_empty()
