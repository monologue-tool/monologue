extends MonologueIndexer


func get_scene() -> PackedScene:
	return PackedScene.new()


func get_metadata() -> Dictionary:
	return {"name": "context", "type": ObjectType.FIELD, "color": Color("ffffff")}
