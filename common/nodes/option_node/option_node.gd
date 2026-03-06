class_name OptionNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("option", "option", false, null, {"export": true, "exposed": false})
	define_property("text", {}, "translatable")
	define_property("enabled", true, "bool", {"visible_in_graph": false})
	define_property("one_shot", false, "bool", {"visible_in_graph": false})
	define_property("condition", "", "text", {"visible_in_graph": false})


func get_type() -> String:
	return "option"


func get_settings() -> Dictionary:
	return {}


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color("e89145")


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
