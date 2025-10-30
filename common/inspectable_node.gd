@abstract
class_name InspectableNode extends InspectableObject

var _displayed_properies: Array = []  # Displayed properties are displayed by default in the GraphNode.
var _exposed_properies: Array = []  # The exposed properties are displayed in the graph node and their values can be overwritten by connecting to their slot on the GraphNode.
var graph_view: GraphNode


func _init(command_manager: CommandManager) -> void:
	# `display` properties are not displayed by default in the node view.
	# `private` properties are not exposable.
	# `protected` properties cannot be edited from the inspector.
	define_property("id", IDGen.generate(), "text", {"private": true}, "Special:Header")
	super._init(command_manager)
	define_property(
		"position", Vector2.ZERO, "vector2", {"private": true, "protected": true}, "Extra"
	)
	define_property("notes", "", "string", {"private": true}, "Extra")


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


@abstract func get_type() -> String

@abstract func get_title() -> String
@abstract func get_color() -> Color
@abstract func get_icon() -> Texture2D
