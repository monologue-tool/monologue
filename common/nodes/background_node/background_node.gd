class_name BackgroundNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("background")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("image")
		.set_type("file")
		.file_filters(["*.png", "*.jpg", "*.jpeg", "*.webp"])
		.required()
		.tooltip("Image shown behind the scene from here on."))


func get_type() -> String:
	return "background"
