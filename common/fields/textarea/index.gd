extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://be0xxn5gocqjo")  # text_field.tscn


func get_metadata() -> Dictionary:
	return {
		"name": "textarea",
		"type": ObjectType.FIELD,
		"color": Color("af85fdff"),
		"default_value": "",
		"compatible_types": ["text"],
		"default_settings":
		{
			PropertySettings.KEY_MULTILINE: true,
			PropertySettings.KEY_ROWS: 3,
		}
	}
