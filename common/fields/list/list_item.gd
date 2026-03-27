@abstract
class_name ListItem extends InspectableObject

const ID_LENGTH: int = 6

var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	define_property(
		"id",
		IDGen.generate(ID_LENGTH),
		"text",
		{
			"visible_in_inspector": true,
			"flat": true,
		},
		"Special:Header"
	)
	super._init(command_manager)


## Define a main property for this list item.
## Items with a main property are automatically exported as sub-ports on the graph.
func define_main_property(pname: String, type: String) -> void:
	define_property(pname, null, type, {
		"visible_in_inspector": false,
		"is_main_property": true,
	})
	_main_property_defined = true


func has_main_property() -> bool:
	return _main_property_defined


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass


@abstract func get_preview_property_names() -> Array[String]
