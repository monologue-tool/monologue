class_name OptionNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("option", "option", false, null, {"export": true, "exposed": false})
	define_property("text", {}, "translatable")
	define_property("enabled", true, "bool", {"visible_in_graph": false})
	define_property("one_shot", false, "bool", {"visible_in_graph": false})
	define_property("condition", "", "text", {"visible_in_graph": false})


func get_type() -> String:
	return "option"
