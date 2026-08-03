extends NodeIndexer


func _init() -> void:
	name = "end"
	display_name = "End"
	description = "Stops the story here."
	category = "Flow"
	color = MonologuePalette.FLOW
	icon_path = "res://ui/assets/icons/media_stop.svg"
	node_script = preload("end_node.gd")
