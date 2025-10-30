## The root node representing the starting point of a dialogue graph.
##
## Root nodes serve as the entry point for dialogue execution. They are
## origin nodes with continuous flow, allowing the dialogue to start
## and proceed automatically to connected nodes.
@icon("res://ui/assets/icons/root.svg")
class_name RootNode extends InspectableNode


## Initializes properties for the root node.
##
## Root nodes currently have no additional properties beyond the base node properties.
func initialize_properties() -> void:
	pass


## Returns the type identifier for root nodes.
func get_type() -> String:
	return "root"


## Returns settings indicating this node is both an origin and continuous node.
func get_settings() -> Dictionary:
	return {"origin": true, "continuous": true}


## Returns the display title for root nodes.
func get_title() -> String:
	return "Root"


## Returns the icon texture for root nodes.
func get_icon() -> Texture2D:
	return Texture2D.new()


## Returns the color used for root nodes in the graph.
func get_color() -> Color:
	return Color.WHITE


## Handles property change events for root nodes.
##
## Currently does nothing but can be overridden for custom behavior.
func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
