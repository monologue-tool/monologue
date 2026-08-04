extends NodeIndexer


func _init() -> void:
	name = "choice"
	display_name = "Choice"
	description = "Branches the story on a choice offered to the player."
	category = "Narration"
	icon_path = "res://ui/assets/icons/choice.svg"
	node_script = preload("choice_node.gd")
