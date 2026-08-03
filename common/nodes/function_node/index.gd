extends NodeIndexer


func _init() -> void:
	name = "function"
	display_name = "Function"
	description = "A named chain that runs when a call reaches it."
	category = "Flow"
	color = MonologuePalette.CONTAINER
	icon_path = ""
	node_script = preload("function_node.gd")
