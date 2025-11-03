extends MonologueIndexer

const NODE_SCRIPT := preload("res://nodes/sentence_node/sentence_node.gd")
const ICON_PATH := "res://ui/assets/icons/text.svg"


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "sentence",
		"type": ObjectType.NODE,
		"display_name": "Sentence",
		"category": "Narration",
		"script": NODE_SCRIPT,
		"icon": ICON_PATH,
		"color": Color("af85fdff")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
