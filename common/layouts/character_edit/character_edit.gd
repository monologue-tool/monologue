extends MarginContainer


signal done


func _ready() -> void:
	hide()
	GlobalSignal.add_listener("open_character_edit", _on_open_character_edit)


func _on_open_character_edit() -> void:
	show()


func _on_button_pressed() -> void:
	hide()


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


func _from_dict(dict: Dictionary) -> void:
	pass
