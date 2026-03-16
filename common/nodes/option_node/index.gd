extends MonologueIndexer

const NODE_SCRIPT := preload("option_node.gd")
const ICON_PATH: String = "res://ui/assets/icons/action.svg"


func get_scene() -> PackedScene:
	return null


func get_metadata() -> Dictionary:
	return {
		"name": "option",
		"type": ObjectType.NODE,
		"display_name": "Option",
		"category": "Flow",
		"script": NODE_SCRIPT,
		"icon": ICON_PATH,
		"color": Color("e89145")
	}


func get_node_script() -> Script:
	return NODE_SCRIPT
