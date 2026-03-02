@icon("res://ui/assets/icons/text.svg")
class_name SentenceNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("sentence", "context", false, null, {"export": true})
	define_property("speaker", "", "dropdown", {"source": "characters"})
	define_property("display_name", "", "text")
	define_property("line", "", "text")
	define_property("voiceline", "", "file", {"visible_in_graph": false})


func get_type() -> String:
	return "sentence"


func get_settings() -> Dictionary:
	return {}


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
