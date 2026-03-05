class_name TextNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("text", "text", true, "", {"exposed": false})


func get_type() -> String:
	return "text"


func get_settings() -> Dictionary:
	return {}


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
