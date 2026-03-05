extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("res://common/fields/file/file_field.tscn")


func get_metadata() -> Dictionary:
	return {
		"name": "file",
		"type": ObjectType.FIELD,
		"color": Color("80c0ffff"),
		"default_value": "",
		"default_settings": {
			PropertySettings.KEY_FILE_FILTERS: [],
		}
	}
