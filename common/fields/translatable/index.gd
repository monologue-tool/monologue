extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://bg1c7vlg63ty1")


func get_metadata() -> Dictionary:
	return {"name": "translatable", "type": ObjectType.FIELD, "color": Color("628cffff")}
