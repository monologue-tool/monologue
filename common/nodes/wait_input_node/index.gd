extends NodeIndexer


func _init() -> void:
	name = "wait_input"
	display_name = "Wait Input"
	description = "Wait for an input before continuing."
	category = "Flow"
	color = MonologuePalette.NUMBER
	icon_path = ""
	node_script = preload("wait_input_node.gd")
