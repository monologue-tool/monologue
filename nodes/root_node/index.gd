extends MonologueIndexer

const NODE_SCRIPT := preload("res://nodes/root_node/root_node.gd")
const ICON_PATH := "res://ui/assets/icons/root.svg"


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "root",
		"type": ObjectType.NODE,
		"display_name": "Root",
		"category": "Flow",
		"script": NODE_SCRIPT,
		"icon": ICON_PATH,
		"color": Color("ffffff")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
