class_name WaitNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("wait")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("seconds")
		.set_type("float")
		.default(1.0)
		.bounds(0.0, 60.0, 0.1)
		.suffix("s")
		.tooltip("How long the story pauses here before carrying on."))


func get_type() -> String:
	return "wait"


## A wait of nothing is a node that does nothing; worth saying, not worth blocking.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if float(get_property_value("seconds")) <= 0.0:
		result.add(
			ValidationIssue.warning(
				"This wait is zero seconds long, so it does nothing.", &"empty_wait"
			).at(self, "seconds")
		)
