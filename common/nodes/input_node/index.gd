extends NodeIndexer


func _init() -> void:
	name = "input"
	display_name = "Input"
	description = "Prompt the user to enter a value."
	category = "Logic"
	color = Color("438ab0ff")
	icon_path = ""
	node_script = preload("input_node.gd")
