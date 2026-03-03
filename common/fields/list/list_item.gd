@abstract
class_name ListItem extends InspectableObject

const ID_LENGTH: int = 6

var storyline_id: String = ""


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


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass
