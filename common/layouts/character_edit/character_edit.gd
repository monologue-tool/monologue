extends MarginContainer


@onready var nicknames_le := %NicknamesLineEdit
@onready var display_name_le := %DisplayNameLineEdit
@onready var description_te := %DescriptionTextEdit

var current_character_field: MonologueCharacterField


func _ready() -> void:
	hide()
	GlobalSignal.add_listener("open_character_edit", _on_open_character_edit)


func _on_open_character_edit(character_field: MonologueCharacterField) -> void:
	current_character_field = character_field
	_from_dict(character_field._to_dict())
	show()


func _on_button_pressed() -> void:
	current_character_field.nicknames = nicknames_le.text
	current_character_field.display_name = display_name_le.text
	current_character_field.description = description_te.text
	
	hide()
	current_character_field = null
	


func _from_dict(dict: Dictionary = {}) -> void:
	nicknames_le.text = dict.get("Nicknames", "")
	display_name_le.text = dict.get("DefaultDisplayName", "")
	description_te.text = dict.get("EditorDescription", "")


func _to_dict() -> Dictionary:
	# Placeholder
	return {
		"Nicknames": "",
		"DefaultDisplayName": "",
		"EditorDescription": "",
		"DefaultPortrait": "Idle",
		"Portraits": {
			"Idle": {
				"PortraitType": "Image",
				"ImagePath": "./assets/idle.png",
				"Offset": [0, 0],
				"Mirror": false
			},
			"Run": {
				"PortraitType": "Animation",
				"Offset": [0, 0],
				"Mirror": false,
				"Animation": {
					"Fps": 25,
					"FrameCount": 7,
					"Layers": [
						{
							"LayerName": "Layer 1",
							"Visible": true,
							"EditorLock": false,
							"Frames": {
								0: {
									"ImagePath": "./assets/run/01.png",
									"Exposure": 1
								},
								1: {
									"ImagePath": "./assets/run/02.png",
									"Exposure": 3
								},
								5: {
									"ImagePath": "./assets/run/03.png",
									"Exposure": 1
								}
							}
						}
					]
				}
			}
		}
	}
