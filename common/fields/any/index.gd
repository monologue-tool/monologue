extends MonologueIndexer


func get_scene() -> PackedScene:
	return PackedScene.new()


func get_metadata() -> Dictionary:
	return {
		"name": "any",
		"type": ObjectType.FIELD,
		"color": Color("87b26cff"),
		"compatible_types": ["*"],
	}
