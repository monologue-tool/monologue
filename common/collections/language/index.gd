extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "languages", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("res://common/collections/language/language_item.gd")
