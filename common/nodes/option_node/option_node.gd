class_name OptionNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("option")
		.set_type("option")
		.main_property()
		.exposed(false)
		.exported())

	define_property(Property.new("text")
		.set_type("translatable")
		.default({})
		.multiline())

	define_property(Property.new("correspondent")
		.set_type("dropdown")
		.source("characters")
		.hidden_in_graph())

	define_property(Property.new("advanced/enabled")
		.set_type("bool")
		.default(true)
		.hidden_in_graph())

	define_property(Property.new("advanced/one_shot")
		.set_type("bool")
		.hidden_in_graph())

	define_property(Property.new("advanced/enable_condition")
		.set_type("bool")
		.hidden_in_graph())

	define_property(Property.new("advanced/condition")
		.set_type("condition")
		.default({})
		.hidden_in_graph())


func get_type() -> String:
	return "option"


## Cross-property check: no single property can see that the condition switch is on
## while the condition itself is blank.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if not get_property_value("enable_condition"):
		return

	var condition: Variant = get_property_value("condition")
	var variable: String = str(condition.get("variable", "")) if condition is Dictionary else ""
	if variable.is_empty():
		result.add(
			ValidationIssue.warning(
				"This option's condition is enabled but empty, so it always shows.",
				&"empty_condition"
			).at(self, "condition")
		)
