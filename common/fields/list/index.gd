extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("uid://d2s4kv1234abc")


func get_metadata() -> Dictionary:
	return {"name": "list", "type": ObjectType.FIELD, "color": Color("b48eadff")}
