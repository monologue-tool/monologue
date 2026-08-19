extends NodeIndexer


func _init() -> void:
	name = "jump"
	display_name = "Jump"
	description = "Continues in another section, without coming back."
	category = "Flow"
	icon_path = "res://ui/assets/icons/arrow_right.svg"
	node_script = preload("jump_node.gd")
