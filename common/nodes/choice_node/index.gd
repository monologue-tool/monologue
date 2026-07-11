extends MonologueIndexer

const NODE_SCRIPT := preload("choice_node.gd")


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "choice",
		"type": ObjectType.NODE,
		"display_name": "Choice",
		"category": "Flow",
		"script": NODE_SCRIPT,
		"color": Color("e89145")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
