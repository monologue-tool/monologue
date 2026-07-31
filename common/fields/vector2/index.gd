extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://bm7pyxhgln22j")


func get_metadata() -> Dictionary:
	return {
		"name": "vector2",
		"type": ObjectType.FIELD,
		"color": Color("09b58dff"),
		"default_value": [0.0, 0.0]
	}
