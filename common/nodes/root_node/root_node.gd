class_name RootNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("root", "context", false, null, {"exposed": false})


func get_type() -> String:
	return "root"
