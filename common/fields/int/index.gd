extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "int",
		"type": ObjectType.FIELD,
		"color": Color("80c0ffff"),
		"default_value": 0,
	}
