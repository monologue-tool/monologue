class_name CheckpointNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("checkpoint")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())


func get_type() -> String:
	return "checkpoint"
