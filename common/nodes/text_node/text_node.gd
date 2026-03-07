class_name TextNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("text", "text", true, "", {"exposed": false})


func get_type() -> String:
	return "text"
