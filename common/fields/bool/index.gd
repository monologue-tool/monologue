extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://c6dvfrwaes07a")


func get_metadata() -> Dictionary:
	return {"name": "bool", "type": ObjectType.FIELD, "color": Color("f2997eff"), "default_value": false}
