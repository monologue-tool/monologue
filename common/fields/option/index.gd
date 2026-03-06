extends MonologueIndexer


func get_scene() -> PackedScene:
	return PackedScene.new()


func get_metadata() -> Dictionary:
	return {
		"name": "option",
		"type": ObjectType.FIELD,
		"color": Color("e89145"),
		"compatible_types": ["option"],
	}
