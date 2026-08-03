extends NodeIndexer


func _init() -> void:
	name = "checkpoint"
	display_name = "Checkpoint"
	description = "Create a checkpoint here."
	category = "Flow"
	color = MonologuePalette.FLOW
	icon_path = ""
	node_script = preload("checkpoint_node.gd")
