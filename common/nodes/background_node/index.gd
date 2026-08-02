extends NodeIndexer


func _init() -> void:
	name = "background"
	display_name = "Background"
	description = "Changes the image shown behind the scene."
	category = "Stage"
	color = Color("6a9fb5")
	icon_path = "res://ui/assets/icons/image_down.svg"
	node_script = preload("background_node.gd")
