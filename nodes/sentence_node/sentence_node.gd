@icon("res://ui/assets/icons/text.svg")
class_name SentenceNode extends InspectableNode


func get_type() -> String:
	return "sentence"


func initialize_properties() -> void:
	define_property("speaker", "", "dropdown")
	define_property("display_name", "", "text")
	define_property("sentence", "", "text")
	define_property("voiceline", "", "file")


func preview() -> void:
	pass


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
