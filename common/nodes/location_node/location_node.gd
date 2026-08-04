## Moves the story to a place.
class_name LocationNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("location")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("locations")
		.label_property("name")
		.required()
		.tooltip("Where the story moves to."))

	define_property(Property.new("show_image")
		.set_type("bool")
		.default(true)
		.hidden_in_graph()
		.tooltip("Whether the place's own image replaces the background."))


func get_type() -> String:
	return "location"
