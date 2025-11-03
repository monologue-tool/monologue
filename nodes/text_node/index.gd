extends MonologueIndexer

const NODE_SCRIPT := preload("res://nodes/text_node/text_node.gd")
const ICON_PATH := "res://ui/assets/icons/text.svg"


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "text",
		"type": ObjectType.NODE,
		"display_name": "Text",
		"category": "Narration",
		"script": NODE_SCRIPT,
		"icon": ICON_PATH,
		"color": Color("af85fdff")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
