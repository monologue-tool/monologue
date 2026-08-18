extends NodeIndexer


func _init() -> void:
	name = "character"
	display_name = "Character"
	description = "Brings a character on stage, takes them off, or changes how they look."
	category = "Stage"
	icon_path = "res://ui/assets/icons/character.svg"
	node_script = preload("character_node.gd")
