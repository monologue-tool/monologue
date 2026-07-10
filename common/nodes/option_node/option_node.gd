class_name OptionNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("option", "option", false, null, {"export": true, "exposed": false})
	define_property("text", {}, "translatable", {"multiline": true})
	define_property("correspondent", "", "dropdown", {"source": "characters", "visible_in_graph": false})
	define_property("enabled", true, "bool", {"visible_in_graph": false}, "Advanced")
	define_property("one_shot", false, "bool", {"visible_in_graph": false}, "Advanced")
	define_property("enable_condition", false, "bool", {"visible_in_graph": false}, "Advanced")
	define_property("condition", {}, "condition", {"visible_in_graph": false}, "Advanced")


func get_type() -> String:
	return "option"
