extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://dlmxs2fcef1a1")


func get_metadata() -> Dictionary:
	return {"name": "bezier", "type": ObjectType.FIELD, "color": Color("9df27eff")}
