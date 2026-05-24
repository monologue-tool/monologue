class_name ProjectSettingsDocument extends InspectableDocument


func initialize_properties() -> void:
	define_property("display_response_in_the_flow", false, "bool")


func get_type() -> String:
	return "manifest"
