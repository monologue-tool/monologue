extends NodeIndexer


func _init() -> void:
	name = "storyline"
	display_name = "Storyline"
	description = "Hands the story over to another storyline."
	category = "Flow"
	icon_path = "res://ui/assets/icons/story_file.svg"
	node_script = preload("storyline_node.gd")
