extends GdUnitTestSuite

## Each rule on its own, with no editor booted.

var _history: CommandManager


func before_test() -> void:
	_history = CommandManager.new()


static func _check(rule: ValidationRule, value: Variant, of_type: String = "text") -> bool:
	var property := Property.new("p").set_type(of_type)
	return rule.check(ValidationContext.for_property(property, null, value)).is_valid()


func test_required_turns_away_blanks_and_nothing_else() -> void:
	var rule := RequiredRule.new()

	for blank: Variant in ["", "   ", null, [], {}]:
		assert_bool(_check(rule, blank)).override_failure_message(
			"%s should count as empty." % str(blank)
		).is_false()

	assert_bool(_check(rule, "hello")).is_true()

	# false and 0 are real values, not blanks. A bool that must be answered is still
	# answered when the answer is no.
	for answered: Variant in [false, 0, 0.0]:
		assert_bool(_check(rule, answered, "bool")).override_failure_message(
			"%s is an answer, not a blank." % str(answered)
		).is_true()


func test_length_and_range_hold_both_ends_and_ignore_what_they_cannot_read() -> void:
	var cases: Array = [
		[LengthRule.new(2, 4), "a", false],
		[LengthRule.new(2, 4), "ab", true],
		[LengthRule.new(2, 4), "abcde", false],
		[RangeRule.new(0, 10), -1, false],
		[RangeRule.new(0, 10), 5, true],
		[RangeRule.new(0, 10), 11, false],
		# A range asked about text has nothing to say, rather than refusing it.
		[RangeRule.new(0, 10), "hello", true],
	]

	for case: Array in cases:
		assert_bool(_check(case[0], case[1])).override_failure_message(
			"%s on %s should be %s." % [case[0].code, str(case[1]), str(case[2])]
		).is_equal(case[2])


func test_unique_waits_for_the_commit_and_then_flags_the_twin() -> void:
	# Renaming A to B when B exists is a legal first half of a swap, so nothing is said
	# while the user is still typing.
	var rule := UniqueRule.new()
	var typing := ValidationContext.for_property(
		Property.new("p").set_type("text"), null, "x", ValidationContext.Phase.LIVE
	)
	assert_bool(rule.applies_to(typing)).is_false()

	for phase: int in [ValidationContext.Phase.COMMIT, ValidationContext.Phase.AUDIT]:
		var settled := ValidationContext.for_property(
			Property.new("p").set_type("text"), null, "x", phase
		)
		assert_bool(rule.applies_to(settled)).is_true()

	var registry := MonologueRegistry.get_instance()
	var character: CollectionItem = registry.create_collection_item("characters", _history)
	var twin: CollectionItem = registry.create_collection_item("characters", _history)
	character.set_property_value("name", "Alice")
	twin.set_property_value("name", "Alice")
	var owner: CollectionItem = registry.create_collection_item("characters", _history)
	owner.set_property_children("portraits", [character, twin])

	assert_bool(
		rule.check(
			ValidationContext.for_property(
				twin.get_property("name"), twin, "Alice", ValidationContext.Phase.COMMIT
			)
		).is_valid()
	).is_false()


func test_a_hand_written_check_sees_the_candidate_and_answers_in_four_ways() -> void:
	var property := Property.new("p").set_type("text")
	var context := ValidationContext.for_property(property, null, "candidate")

	var seen: Array = []
	CallableRule.new(func(c: ValidationContext) -> Variant:
		seen.append(c.value)
		return null).check(context)
	assert_str(seen[0]).is_equal("candidate")

	for answer: Variant in [null, true]:
		assert_bool(
			CallableRule.new(func(_c: ValidationContext) -> Variant: return answer)
				.check(context).is_valid()
		).is_true()

	assert_bool(
		CallableRule.new(func(_c: ValidationContext) -> Variant: return false)
			.check(context).is_valid()
	).is_false()

	var spoken := CallableRule.new(func(_c: ValidationContext) -> Variant: return "too short")
	assert_bool(spoken.check(context).is_valid()).is_false()
	assert_str(spoken.check(context).first_message()).is_equal("too short")


func test_what_a_property_declares_becomes_the_rules_it_is_checked_against() -> void:
	assert_array(
		ValidationService.rules_for(Property.new("bare").set_type("text"))
	).is_empty()

	var declared := Property.new("p").set_type("text").required().min_length(2)
	declared.validate(func(_c: ValidationContext) -> Variant: return null)

	var codes: Array[StringName] = []
	for rule: ValidationRule in ValidationService.rules_for(declared):
		codes.append(rule.code)
	assert_array(codes).contains([&"required", &"length", &"custom"])

	# warn_if is the same road with a different sign at the end: it says its piece without
	# making the value invalid.
	var soft := Property.new("q").set_type("text")
	soft.warn_if(func(_c: ValidationContext) -> Variant: return "just saying")
	var result := ValidationService.validate_value(
		ValidationContext.for_property(soft, null, "x")
	)

	assert_array(result.errors()).is_empty()
	assert_array(result.warnings()).is_not_empty()
	assert_bool(result.is_valid()).is_true()
