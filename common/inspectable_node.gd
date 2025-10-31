@abstract
class_name InspectableNode extends InspectableObject

var graph_view: GraphNode
var _main_property_defined: bool = false


func _init(command_manager: CommandManager) -> void:
	define_property(
		"id", IDGen.generate(), "text", {"private": true, "flat": true}, "Special:Header"
	)
	super._init(command_manager)
	define_property(
		"position", Vector2.ZERO, "vector2", {"private": true, "protected": true}, "Extra"
	)
	define_property("notes", "", "string", {"private": true}, "Extra")

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
	default_settings["display"] = true
	default_settings["exposed"] = true
	default_settings["private"] = false
	default_settings["protected"] = not editable
	default_settings["editable"] = editable
	default_settings["export"] = true
	default_settings["is_main"] = true

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
