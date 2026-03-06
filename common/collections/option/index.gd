extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "option", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("uid://dhodjihl1pyka")
