extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "locations", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("uid://bcl51sy34f52y")
