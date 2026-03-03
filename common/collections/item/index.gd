extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "items", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("uid://y8hn47i11ixd")
