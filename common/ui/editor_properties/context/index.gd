extends MonologueIndexer


func get_scene() -> PackedScene:
	# Not intended to be inspectable
	return PackedScene.new()


func get_metadata() -> Dictionary:
	return {"name": "context", "type": ObjectType.FIELD, "color": Color("ffffff")}
