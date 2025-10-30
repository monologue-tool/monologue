@icon("res://ui/assets/icons/root.svg")
class_name RootNode extends InspectableNode


func initialize_properties() -> void:
	setup_main_property()


func setup_main_property() -> void:
	# Main property is not editable for RootNode
	define_property("title", "Root", "context", {"protected": true}, "General", true)


func get_type() -> String:
	return "root"


func get_settings() -> Dictionary:
	return {"origin": true, "continuous": true}


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
