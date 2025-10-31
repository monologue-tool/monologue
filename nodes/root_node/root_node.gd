@icon("res://ui/assets/icons/root.svg")
class_name RootNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("root", "context", false, null, {"has_input_port": false})


func get_type() -> String:
	return "root"


func get_settings() -> Dictionary:
	return {}


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
