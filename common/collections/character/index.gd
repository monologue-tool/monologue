extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "characters", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("uid://bqu0a4ofohwe4")
