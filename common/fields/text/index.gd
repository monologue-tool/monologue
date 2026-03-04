extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://be0xxn5gocqjo")


func get_metadata() -> Dictionary:
	return {
		"name": "text",
		"type": ObjectType.FIELD,
		"color": Color("af85fdff"),
		"compatible_types": ["textarea"],
	}
