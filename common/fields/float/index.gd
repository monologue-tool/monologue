extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://c7513qgkxx0m8")


func get_metadata() -> Dictionary:
	return {
		"name": "float",
		"type": ObjectType.FIELD,
		"color": Color("45cee9ff"),
		"compatible_types": ["slider", "float"],
		"default_value": 0.0,
		"default_settings": {
			"rounded": false,
			"step": 0.1,
			"allow_greater": true,
			"allow_lesser": true,
		}
	}
