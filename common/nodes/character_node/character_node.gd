class_name CharacterNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("character")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))
	
	define_property(Property.new("who")
		.set_type("reference")
		)

	define_property(Property.new("action")
		.set_type("dropdown")
		.required()
		.tooltip("Storyline to continue into."))


func get_type() -> String:
	return "character"
