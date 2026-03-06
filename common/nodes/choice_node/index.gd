extends MonologueIndexer

const NODE_SCRIPT := preload("choice_node.gd")
const ICON_PATH := "res://ui/assets/icons/action.svg"


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "choice",
		"type": ObjectType.NODE,
		"display_name": "Choice",
		"category": "Flow",
		"script": NODE_SCRIPT,
		"icon": ICON_PATH,
		"color": Color("e89145")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
