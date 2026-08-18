class_name BoolNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("bool")
		.set_type("bool")
		.default(false)
		.main_property()
		.editable()
		.exposed(false)
		.exported())


func get_type() -> String:
	return "bool"
