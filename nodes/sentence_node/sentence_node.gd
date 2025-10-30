## Dialogue sentence with speaker, text, and optional voiceline
@icon("res://ui/assets/icons/text.svg")
class_name SentenceNode extends InspectableNode


func initialize_properties() -> void:
	define_property("speaker", "", "dropdown")
	define_property("display_name", "", "text")
	define_property("sentence", "", "text")
	define_property("voiceline", "", "file", {"display": false})


func get_type() -> String:
	return "sentence"


func get_settings() -> Dictionary:
	return {"continuous": true}


func get_title() -> String:
	return "Sentence"


func get_icon() -> Texture2D:
	return Texture2D.new()


func get_color() -> Color:
	return Color.WHITE


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
