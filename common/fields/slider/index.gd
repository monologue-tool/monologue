extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://bap1tk0q1l1kf")


func get_metadata() -> Dictionary:
	return {
		"name": "slider",
		"type": ObjectType.FIELD,
		"color": Color("45cee9ff"),
		"default_value": 0.0,
		"compatible_types": ["int", "float"]
	}
