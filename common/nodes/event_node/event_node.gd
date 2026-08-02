## Watches a variable while the story runs elsewhere, and takes over when it matches.
##
## Unlike a condition node, which is tested once as the story passes through, this one
## stays armed: its branch runs the moment the test becomes true, wherever the story is.
class_name EventNode extends InspectableNode


func initialize_properties() -> void:
	# No input: an event is armed for the whole run, not entered from a wire. Its port
	# would be one nothing could ever connect to.
	define_property(Property.new("event")
		.set_type("context")
		.main_property()
		.exposed(false)
		.not_exposable()
		.exported())

	define_property(Property.new("test")
		.set_type("condition")
		.hidden_in_graph())

	define_property(Property.new("advanced/one_shot")
		.set_type("bool")
		.default(true)
		.hidden_in_graph()
		.tooltip("Fires once, then stays quiet for the rest of the run."))


func get_type() -> String:
	return "event"


## An event with nothing to watch never fires, which is worth saying out loud.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	var test: Variant = get_property_value("test")
	var variable: String = str(test.get("variable", "")) if test is Dictionary else ""
	if variable.is_empty():
		result.add(
			ValidationIssue.warning(
				"This event watches no variable, so it never fires.", &"empty_event"
			).at(self, "test")
		)
