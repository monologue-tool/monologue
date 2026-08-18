extends NodeIndexer


func _init() -> void:
	name = "option"
	display_name = "Option"
	description = "A single reusable option that can be plugged into a choice node."
	category = "Narration"
	enterable = false
	icon_path = "res://ui/assets/icons/action.svg"
	node_script = preload("option_node.gd")
