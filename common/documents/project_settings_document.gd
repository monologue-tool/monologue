class_name ProjectSettingsDocument extends InspectableDocument


func initialize_properties() -> void:
	define_property(Property.new("display_response_in_the_flow")
		.set_type("bool"))


func get_type() -> String:
	return "settings"
