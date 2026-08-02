class_name InputNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("input")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())
	
	define_property(Property.new("text")
		.set_type("translatable")
		.default({"en": "Enter something here:"})
		.hidden_in_graph())
	
	define_property(Property.new("variable")
		.set_type("reference")
		.reference_scope("variables")
		.label_property("name")
		.hidden_in_graph())
	
	define_property(Property.new("placeholder")
		.set_type("translatable")
		.hidden_in_graph())
	
	define_property(Property.new("allow_empty")
		.set_type("bool")
		.default(false)
		.hidden_in_graph())


func get_type() -> String:
	return "input"
