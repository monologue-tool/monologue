extends NodeIndexer


func _init() -> void:
	name = "input"
	display_name = "Input"
	description = "Asks the player to type something, and keeps it in a variable."
	category = "Narration"
	icon_path = "res://ui/assets/icons/text.svg"
	node_script = preload("input_node.gd")
