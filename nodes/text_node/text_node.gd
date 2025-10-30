## A simple text node for displaying text content in the graph.
##
## Text nodes contain a single text property that can be exported.
## They serve as origin nodes (entry points) in the dialogue graph.
@icon("res://ui/assets/icons/text.svg")
class_name TextNode extends InspectableNode


## Initializes the text property for this node.
func initialize_properties() -> void:
	define_property("text", "", "text", {"export": true})


## Returns the type identifier for text nodes.
func get_type() -> String:
	return "text"


## Returns settings indicating this node type is an origin node.
func get_settings() -> Dictionary:
	return {"origin": true}


## Returns the display title for text nodes.
func get_title() -> String:
	return "Text"


## Returns the icon texture for text nodes.
func get_icon() -> Texture2D:
	return Texture2D.new()


## Returns the color used for text nodes in the graph.
func get_color() -> Color:
	return Color.WHITE


## Handles property change events for text nodes.
##
## Currently does nothing but can be overridden for custom behavior.
func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
