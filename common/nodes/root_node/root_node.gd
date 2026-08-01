class_name RootNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("root")
		.set_type("context")
		.main_property()
		.exposed(false)
		.exported())


func get_type() -> String:
	return "root"
