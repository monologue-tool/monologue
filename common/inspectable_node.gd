## Abstract base class for nodes in the graph editor.
##
## Extends InspectableObject to add graph node-specific functionality.
## Nodes in the dialogue graph inherit from this class to gain property
## inspection, visual representation, and graph editing capabilities.
@abstract
class_name InspectableNode extends InspectableObject

## Array of property names that are displayed directly in the GraphNode view.
var _displayed_properies: Array = []  # Displayed properties are displayed by default in the GraphNode.

## Reference to the visual GraphNode representation of this node.
var graph_view: GraphNode


## Initializes the inspectable node with required properties.
##
## Sets up standard node properties including ID, position, and notes.
## [br][br]
## [param command_manager] CommandManager for undo/redo support.
func _init(command_manager: CommandManager) -> void:
	# `display` properties are not displayed by default in the node view.
	# `private` properties are not exposable.
	# `protected` properties cannot be edited from the inspector.
	define_property(
		"id", IDGen.generate(), "text", {"private": true, "flat": true}, "Special:Header"
	)
	super._init(command_manager)
	define_property(
		"position", Vector2.ZERO, "vector2", {"private": true, "protected": true}, "Extra"
	)
	define_property("notes", "", "string", {"private": true}, "Extra")


## Defines a property for this node with optional display in GraphNode.
##
## Extends the base define_property to support displaying properties
## directly in the node's visual representation.
## [br][br]
## [param pname] The property name/identifier.
## [br][br]
## [param default_value] The initial value for the property.
## [br][br]
## [param type] The property type.
## [br][br]
## [param options] Optional dictionary of property-specific settings.
## [br][br]
## [param category] The category this property belongs to. Default is "General".
## [br][br]
## [param display] Whether to display this property in the GraphNode view. Default is false.
func define_property(
	pname: String,
	default_value: Variant,
	type: String,
	options: Dictionary = {},
	category: String = "General",
	display: bool = false
) -> void:
	super.define_property(pname, default_value, type, options, category)

	if display:
		_displayed_properies.append(pname)


## Returns the type identifier string for this node.
##
## Must be implemented by subclasses (e.g., "sentence", "choice", "condition").
@abstract func get_type() -> String

## Returns the display title for this node type.
##
## Must be implemented by subclasses (e.g., "Sentence", "Choice", "Condition").
@abstract func get_title() -> String

## Returns the color to use for this node type in the graph.
##
## Must be implemented by subclasses.
@abstract func get_color() -> Color

## Returns the icon texture for this node type.
##
## Must be implemented by subclasses.
@abstract func get_icon() -> Texture2D
