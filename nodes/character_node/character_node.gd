class_name CharacterNode extends MonologueGraphNode

var character := Property.new(DROPDOWN, {"store_index": true}, 0)
var action_type := Property.new(DROPDOWN, {}, "Join")

var _position := Property.new(DROPDOWN, {}, "Left")
var join_animation := Property.new(DROPDOWN, {}, "Default", "Animation Type")
var leave_animation := Property.new(DROPDOWN, {}, "Default", "Animation Type")
var update_animation := Property.new(DROPDOWN, {}, "Default", "Animation Type")
var portrait := Property.new(DROPDOWN, {"late_items": true})
var duration := Property.new(SPINBOX, {"step": 0.1, "minimum": 0.0}, 0.5)
var _z_index := Property.new(SPINBOX, {"step": 1}, 0)
var mirrored := Property.new(TOGGLE, {}, false)

var _control_groups = {
	"Join": [portrait, _z_index, join_animation, _position, mirrored],
	"Leave": [leave_animation],
	"Update": [portrait, _z_index, update_animation, _position, mirrored],
}

@onready var character_name_label := %CharacterNameLabel
@onready var action_type_label := %ActionTypeLabel
@onready var display_container := %DisplayContainer
@onready var position_label := %PositionLabel
@onready var portrait_name_label := %PortraitNameLabel


func _ready():
	node_type = "NodeCharacter"

	var characters: Array = get_graph_edit().characters.value
	character.callers["set_items"] = [characters, "Character/Name", "EditorIndex"]
	character.connect("preview", _update)

	portrait.connect("preview", _update)

	action_type.callers["set_items"] = [
		[
			{"id": 0, "text": "Join"},
			{"id": 1, "text": "Leave"},
			{"id": 2, "text": "Update"},
		]
	]
	action_type.connect("preview", _show_group)
	action_type.connect("preview", _update)

	_position.callers["set_items"] = [
		[
			{"id": 0, "text": "Left"},
			{"id": 1, "text": "Center"},
			{"id": 2, "text": "Right"},
		]
	]
	_position.connect("preview", _update)

	join_animation.callers["set_items"] = [
		[
			{"id": 0, "text": "Default"},
			{"id": 1, "text": "None"},
			{"id": 2, "text": "Fade In"},
			{"id": 3, "text": "Slide In Auto"},
			{"id": 4, "text": "Slide In Down"},
			{"id": 5, "text": "Slide In Left"},
			{"id": 6, "text": "Slide In Right"},
			{"id": 7, "text": "Slide In Up"},
		]
	]
	join_animation.connect("preview", _update)

	leave_animation.callers["set_items"] = [
		[
			{"id": 0, "text": "Default"},
			{"id": 1, "text": "None"},
			{"id": 2, "text": "Fade Out"},
			{"id": 3, "text": "Slide Out Auto"},
			{"id": 4, "text": "Slide Out Down"},
			{"id": 5, "text": "Slide Out Left"},
			{"id": 6, "text": "Slide Out Right"},
			{"id": 7, "text": "Slide Out Up"},
		]
	]
	leave_animation.connect("preview", _update)

	update_animation.callers["set_items"] = [
		[
			{"id": 0, "text": "Default"},
			{"id": 1, "text": "None"},
			{"id": 2, "text": "Bounce"},
			{"id": 3, "text": "Shake"},
		]
	]
	update_animation.connect("preview", _update)

	super._ready()
	_show_group()
	_update()


func _update(_value: Variant = null) -> void:
	await get_tree().process_frame
	super._update()

	var action: Variant = action_type.value
	var characters: Array = get_graph_edit().characters.value
	character.callers["set_items"] = [characters, "Character/Name", "EditorIndex"]
	if characters[character.value] and characters[character.value]["Character"].has("Portraits"):
		if portrait.field:
			portrait.field.set_items(characters[character.value]["Character"]["Portraits"], "Name")
		else:
			portrait.setters["set_items"] = [
				characters[character.value]["Character"]["Portraits"], "Name"
			]

	display_container.visible = action != "Leave"
	character_name_label.text = characters[character.value].get("Character", {}).get(
		"Name", "Unknown"
	)
	action_type_label.text = action
	position_label.text = _position.value
	portrait_name_label.text = portrait.value if portrait.value else "Unknown"


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
	return [
		"character",
		"action_type",
		{
			"Display Settings":
			[
				"portrait",
				"_z_index",
				{
					"Animation":
					["join_animation", "leave_animation", "update_animation", "duration"]
				},
				"_position",
				"mirrored"
			]
		}
	]
