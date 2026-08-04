extends NodeIndexer


func _init() -> void:
	name = "jump"
	display_name = "Jump"
	description = "Continues the story at a label, without drawing a wire across the graph."
	category = "Flow"
	icon_path = "res://ui/assets/icons/arrow_right.svg"
	node_script = preload("jump_node.gd")
