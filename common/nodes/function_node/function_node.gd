## The start of a chain that runs when something calls it.
##
## Like root, it is entered rather than reached: no wire arrives here. What follows it
## is the body, and wherever that body runs out is an exit the caller can carry on from.
class_name FunctionNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("function")
		.set_type("context")
		.main_property()
		.exposed(false)
		.not_exposable()
		.exported())


func get_type() -> String:
	return "function"


## A function nothing can name is a function nothing can call.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("label")).strip_edges().is_empty():
		result.add(
			ValidationIssue.warning(
				"This function has no name, so a call cannot tell it from another.",
				&"unnamed_function"
			).at(self, "label")
		)
