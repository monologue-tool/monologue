extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "portraits", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("uid://brhhri86u8h56")
