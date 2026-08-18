class_name WaitInputNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("wait_input")
		.main_property()
		.set_type("context")
		.exposed()
		.exported())

	define_property(Property.new("hide_text_box")
		.set_type("bool")
		.default(false)
		.hidden_in_graph())


func get_type() -> String:
	return "wait_input"
