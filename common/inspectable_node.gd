## Base class for dialogue graph nodes with property inspection and visualization
@abstract
class_name InspectableNode extends InspectableObject

var _displayed_properies: Array = []  # Properties shown directly in GraphNode
var graph_view: GraphNode


func _init(command_manager: CommandManager) -> void:
	# All nodes get id, position, and notes as base properties
	# private: not exposable, protected: not editable, flat: no label
	define_property(
		"id", IDGen.generate(), "text", {"private": true, "flat": true}, "Special:Header"
	)
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
