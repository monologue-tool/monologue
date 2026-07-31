extends MonologueIndexer


func get_scene() -> PackedScene:
	return preload("res://common/fields/collection/collection_field.tscn")


func get_metadata() -> Dictionary:
	return {
		"name": "collection",
		"type": ObjectType.FIELD,
		"color": Color("b48eadff"),
		"default_value": []
	}
