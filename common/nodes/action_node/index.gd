extends NodeIndexer


func _init() -> void:
	name = "action"
	display_name = "Action"
	description = "Tells the game to do something Monologue knows nothing about."
	category = "Logic"
	icon_path = "res://ui/assets/icons/action.svg"
	node_script = preload("action_node.gd")
