extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://b6bfebqeejpsg")


func get_metadata() -> Dictionary:
	return {
		"name": "condition",
		"type": ObjectType.FIELD,
		"color": Color("d1b37bff"),
		"default_value": {"variable": "", "operator": ">=", "value": true}
	}
