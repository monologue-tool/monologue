## A dialogue sentence node representing spoken dialogue in the graph.
##
## Sentence nodes contain dialogue text with optional speaker information,
## display names, and voiceline audio. They are the primary node type for
## creating character dialogue in Monologue.
@icon("res://ui/assets/icons/text.svg")
class_name SentenceNode extends InspectableNode


## Initializes the properties specific to sentence nodes.
##
## Sets up speaker, display name, sentence text, and voiceline properties.
func initialize_properties() -> void:
	define_property("speaker", "", "dropdown")
	define_property("display_name", "", "text")
	define_property("sentence", "", "text")
	define_property("voiceline", "", "file", {"display": false})


## Returns the type identifier for sentence nodes.
func get_type() -> String:
	return "sentence"


## Returns settings indicating this node type allows continuous flow.
func get_settings() -> Dictionary:
	return {"continuous": true}


## Returns the display title for sentence nodes.
func get_title() -> String:
	return "Sentence"


## Returns the icon texture for sentence nodes.
func get_icon() -> Texture2D:
	return Texture2D.new()


## Returns the color used for sentence nodes in the graph.
func get_color() -> Color:
	return Color.WHITE


## Handles property change events for sentence nodes.
##
## Currently does nothing but can be overridden for custom behavior.
func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
