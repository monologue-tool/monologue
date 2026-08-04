extends NodeIndexer


func _init() -> void:
	name = "checkpoint"
	display_name = "Checkpoint"
	description = "Marks a place the story can be resumed from."
	category = "Flow"
	icon_path = "res://ui/assets/icons/media_skip_backward.svg"
	node_script = preload("checkpoint_node.gd")
