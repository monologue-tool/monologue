@icon("res://ui/assets/icons/root.svg")
class_name RootNode extends InspectableNode


func initialize_properties() -> void:
	pass


func get_type() -> String:
	return "root"


func get_settings() -> Dictionary:
	return {"origin": true, "continuous": true}


func get_title() -> String:
	return "Root"


func get_title_type() -> String:
	return "context"


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
