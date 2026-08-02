extends NodeIndexer


func _init() -> void:
	name = "condition"
	display_name = "Condition"
	description = "Sends the story one way or the other depending on a variable."
	category = "Flow"
	color = Color("d1b37b")
	icon_path = "res://ui/assets/icons/condition.svg"
	node_script = preload("condition_node.gd")
