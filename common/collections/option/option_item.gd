class_name OptionCollectionItem extends ListItem


func initialize_properties() -> void:
	define_main_property("option", "option")
	define_property("text", {}, "translatable", {"multiline": true})
	define_property("enabled", true, "bool")
	define_property("one_shot", false, "bool")
	define_property("condition", "", "condition")
	define_property("description", "", "textarea", {}, "Extra")


func get_type() -> String:
	return "option"


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass


func get_preview_property_names() -> Array[String]:
	return ["text"]
