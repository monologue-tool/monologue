extends NodeIndexer


func _init() -> void:
	name = "reroute"
	display_name = "Reroute"
	description = "Bends a wire without changing anything about the story."
	category = "Flow"
	color = MonologuePalette.CONTAINER
	icon_path = "res://ui/assets/icons/link.svg"
	node_script = preload("reroute_node.gd")
