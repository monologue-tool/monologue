extends NodeIndexer


func _init() -> void:
	name = "character"
	display_name = "Character"
	description = "Branches the story on a choice offered to the player."
	category = "Flow"
	color = Color("eb5074ff")
	node_script = preload("character_node.gd")
