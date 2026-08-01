class_name TextNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("text")
		.set_type("text")
		.main_property()
		.editable()
		.exposed(false)
		.exported())


func get_type() -> String:
	return "text"
