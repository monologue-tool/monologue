extends NodeIndexer


func _init() -> void:
	name = "choice"
	display_name = "Choice"
	description = "Branches the story on a choice offered to the player."
	category = "Flow"
	icon_path = "res://ui/assets/icons/choice.svg"
	color = Color("e89145")
	node_script = preload("choice_node.gd")
