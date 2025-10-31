@abstract
class_name InspectableNode extends InspectableObject

var graph_view: GraphNode
var _main_property_defined: bool = false


func _init(command_manager: CommandManager) -> void:
	define_property(
		"id", IDGen.generate(), "text", 
		{"visible_in_graph": false, "visible_in_inspector": false, "flat": true}, 
		"Special:Header"
	)
	super._init(command_manager)
	define_property(
		"position", Vector2.ZERO, "vector2", 
		{"visible_in_graph": false, "visible_in_inspector": false, "editable": false}, 
		"Extra"
	)
	define_property(
		"notes", "", "string", 
		{"visible_in_graph": false, "visible_in_inspector": true}, 
		"Extra"
	)

	if not _main_property_defined:
		push_error("Main property not defined")


func define_main_property(
	pname: String,
	type: String,
	editable: bool = false,
	default_value: Variant = null,
	psettings: Dictionary = {},
	category: String = "General"
) -> void:
	if _main_property_defined:
		push_error("Main property already defined")
		return

	var default_settings: Dictionary = {}
	default_settings["visible_in_graph"] = true
	default_settings["visible_in_inspector"] = true
	default_settings["editable"] = editable
	default_settings["has_input_port"] = true
	default_settings["has_output_port"] = true
	default_settings["is_main_property"] = true

	psettings.merge(default_settings)

	define_property(pname, default_value, type, psettings, category)
	_main_property_defined = true


func define_property(
	pname: String,
	default_value: Variant,
	ptype: String,
	psettings: Dictionary = {},
	category: String = "General"
) -> void:
	super.define_property(pname, default_value, ptype, psettings, category)


@abstract func get_type() -> String

@abstract func get_color() -> Color
@abstract func get_icon() -> Texture2D
