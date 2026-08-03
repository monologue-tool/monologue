## Splits the story in two on the value of a variable.
class_name ConditionNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("condition")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("test")
		.set_type("condition")
		.default({})
		.hidden_in_graph())

	define_property(Property.new("pass")
		.set_type("context")
		.exported()
		.not_exposable()
		.hidden_in_inspector())

	define_property(Property.new("fail")
		.set_type("context")
		.exported()
		.not_exposable()
		.hidden_in_inspector())


func get_type() -> String:
	return "condition"


## A condition with no variable always takes the same branch, which makes the node a
## detour rather than a decision.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	var test: Variant = get_property_value("test")
	var variable: String = str(test.get("variable", "")) if test is Dictionary else ""
	if variable.is_empty():
		result.add(
			ValidationIssue.warning(
				"This condition tests nothing, so it always takes the same branch.",
				&"empty_condition"
			).at(self, "test")
		)
