extends MonologueIndexer

const NODE_SCRIPT := preload("uid://bm2we18ivulms")


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "sentence",
		"type": ObjectType.NODE,
		"display_name": "Sentence",
		"category": "Narration",
		"script": NODE_SCRIPT,
		"color": Color("af85fdff")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
