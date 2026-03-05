extends MonologueIndexer

const NODE_SCRIPT := preload("uid://hoqcsoq3aicf")
const ICON_PATH := "res://ui/assets/icons/action.svg"


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "zoo",
		"type": ObjectType.NODE,
		"display_name": "Zoo",
		"category": "_technical",
		"script": NODE_SCRIPT,
		"icon": ICON_PATH,
		"color": Color("af85fdff")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
