extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://dywxnyncdf55t")


func get_metadata() -> Dictionary:
	return {"name": "color", "type": ObjectType.FIELD, "color": Color("d1b37bff"), "default_value": "#000000"}
