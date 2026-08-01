# gdlint: disable=max-public-methods
# (a test suite is one public method per case, by design)
extends GdUnitTestSuite

## Each rule on its own, with no editor booted.

var _history: CommandManager


func before_test() -> void:
	_history = CommandManager.new()


func _context(property: Property, phase: int = ValidationContext.Phase.COMMIT) -> ValidationContext:
	return ValidationContext.for_property(property, null, property.get_value(), phase)


# --- required ---------------------------------------------------------------------


func test_required_rejects_empty_values() -> void:
	var rule := RequiredRule.new()
	for empty_value: Variant in ["", "   ", null, [], {}]:
		var property := Property.new("p").set_type("text").default(empty_value)
		var context := ValidationContext.for_property(property, null, empty_value)
		assert_bool(rule.check(context).is_valid()).override_failure_message(
			"%s should count as empty." % str(empty_value)
		).is_false()


func test_required_accepts_anything_else() -> void:
	var rule := RequiredRule.new()
	var property := Property.new("p").set_type("text").default("hello")
	assert_bool(rule.check(_context(property)).is_valid()).is_true()


func test_required_accepts_false_and_zero() -> void:
	# false and 0 are real values, not blanks. A bool that must be answered is still
	# answered when the answer is no.
	var rule := RequiredRule.new()
	for value: Variant in [false, 0, 0.0]:
		var property := Property.new("p").set_type("bool").default(value)
		var context := ValidationContext.for_property(property, null, value)
		assert_bool(rule.check(context).is_valid()).is_true()


# --- unique -----------------------------------------------------------------------


func test_unique_is_skipped_while_typing() -> void:
	# Renaming A to B when B exists is a legal first half of a swap.
	var rule := UniqueRule.new()
	var context := ValidationContext.for_property(
		Property.new("p").set_type("text"), null, "x", ValidationContext.Phase.LIVE
	)
	assert_bool(rule.applies_to(context)).is_false()


func test_unique_runs_on_commit_and_audit() -> void:
	var rule := UniqueRule.new()
	for phase: int in [ValidationContext.Phase.COMMIT, ValidationContext.Phase.AUDIT]:
		var context := ValidationContext.for_property(
			Property.new("p").set_type("text"), null, "x", phase
		)
		assert_bool(rule.applies_to(context)).is_true()


func test_unique_flags_a_duplicate_among_siblings() -> void:
	var registry := MonologueRegistry.get_instance()
	var character: CollectionItem = registry.create_collection_item("characters", _history)
	var twin: CollectionItem = registry.create_collection_item("characters", _history)
	character.set_property_value("name", "Alice")
	twin.set_property_value("name", "Alice")

	var owner: CollectionItem = registry.create_collection_item("characters", _history)
	owner.set_property_children("portraits", [character, twin])

	var context := ValidationContext.for_property(
		twin.get_property("name"), twin, "Alice", ValidationContext.Phase.COMMIT
	)

	assert_bool(UniqueRule.new().check(context).is_valid()).is_false()


# --- length and range -------------------------------------------------------------


func test_length_rule_enforces_both_bounds() -> void:
	var rule := LengthRule.new(2, 4)
	var property := Property.new("p").set_type("text")

	assert_bool(rule.check(ValidationContext.for_property(property, null, "a")).is_valid()).is_false()
	assert_bool(rule.check(ValidationContext.for_property(property, null, "ab")).is_valid()).is_true()
	assert_bool(
		rule.check(ValidationContext.for_property(property, null, "abcde")).is_valid()
	).is_false()


func test_range_rule_enforces_both_bounds() -> void:
	var rule := RangeRule.new(0, 10)
	var property := Property.new("p").set_type("int")

	assert_bool(rule.check(ValidationContext.for_property(property, null, -1)).is_valid()).is_false()
	assert_bool(rule.check(ValidationContext.for_property(property, null, 5)).is_valid()).is_true()
	assert_bool(rule.check(ValidationContext.for_property(property, null, 11)).is_valid()).is_false()


func test_range_rule_ignores_values_that_are_not_numbers() -> void:
	var rule := RangeRule.new(0, 10)
	var property := Property.new("p").set_type("text")
	assert_bool(
		rule.check(ValidationContext.for_property(property, null, "hello")).is_valid()
	).is_true()


# --- hand-written checks ----------------------------------------------------------


func test_a_validator_may_return_null_true_false_or_a_message() -> void:
	var property := Property.new("p").set_type("text")
	var context := ValidationContext.for_property(property, null, "x")

	assert_bool(CallableRule.new(func(_c: ValidationContext) -> Variant: return null)
		.check(context).is_valid()).is_true()
	assert_bool(CallableRule.new(func(_c: ValidationContext) -> Variant: return true)
		.check(context).is_valid()).is_true()
	assert_bool(CallableRule.new(func(_c: ValidationContext) -> Variant: return false)
		.check(context).is_valid()).is_false()
	assert_bool(CallableRule.new(func(_c: ValidationContext) -> Variant: return "nope")
		.check(context).is_valid()).is_false()


func test_a_validators_message_reaches_the_issue() -> void:
	var property := Property.new("p").set_type("text")
	var context := ValidationContext.for_property(property, null, "x")
	var rule := CallableRule.new(func(_c: ValidationContext) -> Variant: return "too short")

	assert_str(rule.check(context).first_message()).is_equal("too short")


func test_a_validator_receives_the_candidate_value() -> void:
	var seen: Array = []
	var property := Property.new("p").set_type("text")
	var rule := CallableRule.new(func(c: ValidationContext) -> Variant:
		seen.append(c.value)
		return null)

	rule.check(ValidationContext.for_property(property, null, "candidate"))

	assert_str(seen[0]).is_equal("candidate")


func test_warn_if_produces_a_warning_not_an_error() -> void:
	var property := Property.new("p").set_type("text")
	property.warn_if(func(_c: ValidationContext) -> Variant: return "just saying")

	var result := ValidationService.validate_value(
		ValidationContext.for_property(property, null, "x")
	)

	assert_array(result.errors()).is_empty()
	assert_array(result.warnings()).is_not_empty()
	# Warnings do not make a value invalid.
	assert_bool(result.is_valid()).is_true()


# --- assembling the rules ---------------------------------------------------------


func test_declared_options_become_rules() -> void:
	var property := Property.new("p").set_type("text").required().min_length(2)
	property.validate(func(_c: ValidationContext) -> Variant: return null)

	var codes: Array[StringName] = []
	for rule: ValidationRule in ValidationService.rules_for(property):
		codes.append(rule.code)

	assert_array(codes).contains([&"required", &"length", &"custom"])


func test_a_property_with_no_declaration_has_nothing_to_check() -> void:
	var property := Property.new("p").set_type("text")
	assert_array(ValidationService.rules_for(property)).is_empty()
