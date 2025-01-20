class_name CharacterNode extends MonologueGraphNode


var character        := Property.new(DROPDOWN, { "store_index": true }, 0)
var action_type      := Property.new(DROPDOWN, {}, "Join" )

var _position        := Property.new(DROPDOWN, {}, "Left")
var join_animation   := Property.new(DROPDOWN, {}, "Default", "Animation Type")
var leave_animation  := Property.new(DROPDOWN, {}, "Default", "Animation Type")
var update_animation := Property.new(DROPDOWN, {}, "Default", "Animation Type")
var duration         := Property.new(SPINBOX, { "step": 0.1, "minimum": 0.0 }, 0.5)
var _z_index         := Property.new(SPINBOX, { "step": 1 }, 0)
var mirrored         := Property.new(TOGGLE, {}, false)

var _control_groups = {
	"Join": [_z_index, join_animation, _position, mirrored],
	"Leave": [leave_animation],
	"Update": [_z_index, update_animation, _position, mirrored],
}

@onready var action_type_label := $CharacterContainer/HBoxContainer/ActionTypeLabel
@onready var display_container := $CharacterContainer/HBoxContainer/DisplayContainer
@onready var position_label := $CharacterContainer/HBoxContainer/DisplayContainer/PositionLabel


func _ready():
	node_type = "NodeCharacter"
	action_type.callers["set_items"] = [[
		{ "id": 0, "text": "Join"  },
		{ "id": 1, "text": "Leave" },
		{ "id": 2, "text": "Update" },
	]]
	action_type.connect("preview", _show_group)
	action_type.connect("preview", _update)
	
	_position.callers["set_items"] = [[
		{ "id": 0, "text": "Left"  },
		{ "id": 1, "text": "Center" },
		{ "id": 2, "text": "Right" },
	]]
	_position.connect("preview", _update)
	
	join_animation.callers["set_items"] = [[
		{ "id": 0, "text": "Default"        },
		{ "id": 1, "text": "None"           },
		{ "id": 2, "text": "Fade In"        },
		{ "id": 3, "text": "Slide In Auto"  },
		{ "id": 4, "text": "Slide In Down"  },
		{ "id": 5, "text": "Slide In Left"  },
		{ "id": 6, "text": "Slide In Right" },
		{ "id": 7, "text": "Slide In Up"    },
	]]
	join_animation.connect("preview", _update)
	
	leave_animation.callers["set_items"] = [[
		{ "id": 0, "text": "Default"         },
		{ "id": 1, "text": "None"            },
		{ "id": 2, "text": "Fade Out"        },
		{ "id": 3, "text": "Slide Out Auto"  },
		{ "id": 4, "text": "Slide Out Down"  },
		{ "id": 5, "text": "Slide Out Left"  },
		{ "id": 6, "text": "Slide Out Right" },
		{ "id": 7, "text": "Slide Out Up"    },
	]]
	leave_animation.connect("preview", _update)
	
	update_animation.callers["set_items"] = [[
		{ "id": 0, "text": "Default" },
		{ "id": 1, "text": "None"    },
		{ "id": 2, "text": "Bounce"  },
		{ "id": 3, "text": "Shake"   },
	]]
	update_animation.connect("preview", _update)
	
	super._ready()
	_show_group()
	_update()


func _update(value: Variant = null) -> void:
	super._update()
	await get_tree().process_frame
	
	var action: Variant = action_type.value
	character.callers["set_items"] = [get_graph_edit().speakers, "Character/Name", "EditorIndex"]
	
	display_container.visible = action != "Leave"
	action_type_label.text = action
	position_label.text = _position.value
	


func _show_group(act_type: Variant = action_type.value) -> void:
	for key in _control_groups.keys():
		for property in _control_groups.get(key):
			property.visible = false
	
	for key in _control_groups.keys():
		for property in _control_groups.get(key):
			if key == act_type:
				property.visible = true
	title = node_type


func _get_field_groups() -> Array:
	return ["character", "action_type", {"Display Settings": ["_z_index", {"Animation": ["join_animation", "leave_animation", "update_animation", "duration"]}, "_position", "mirrored"]}]
