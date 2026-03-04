extends MonologueIndexer


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {"name": "beziers", "type": ObjectType.COLLECTION}


func get_collection_item_script() -> Script:
	return preload("uid://cyubx671gs3ng")
